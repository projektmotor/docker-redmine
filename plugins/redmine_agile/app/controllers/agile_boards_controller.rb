# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

class AgileBoardsController < ApplicationController
  unloadable

  menu_item :agile

  before_action :find_issue, only: [:update, :issue_tooltip, :inline_comment, :edit_issue, :update_issue, :agile_data]
  before_action :find_optional_project, only: [
                                               :index,
                                               :create_issue,
                                               :backlog_load_more,
                                               :backlog_autocomplete
                                              ]
  before_action :authorize, except: [:index, :edit_issue, :update_issue]

  accept_api_auth :agile_data

  helper :issues
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include RedmineAgile::Helpers::AgileHelper
  helper :checklists if RedmineAgile.use_checklist?
  helper :agile_sprints
  include AgileSprintsHelper

  def index
    retrieve_agile_query
    if @query.valid?
      @issues = @query.issues
      @issue_board = @query.issue_board
      @board_columns = @query.board_statuses
      @allowed_statuses = statuses_allowed_for_create
      @swimlanes = @query.swimlanes
      @closed_swimline_ids = params[:closed_swimline_ids] || []

      @backlog_issues = @query.backlog_issues(params) if @query.backlog_column?

      respond_to do |format|
        format.html { render :template => 'agile_boards/index', :layout => !request.xhr? }
        format.js
      end
    else
      respond_to do |format|
        format.html { render(:template => 'agile_boards/index', :layout => !request.xhr?) }
        format.js
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update
    (render_error_message(l(:label_agile_action_not_available)); return false) unless @issue.editable?
    retrieve_agile_query_from_session
    old_status = @issue.status
    @issue.init_journal(User.current)

    @issue.safe_attributes = configured_params['issue']
    if configured_params['issue'] && configured_params['issue']['sprint_id']
      old_sp = @issue.agile_data.agile_sprint
      new_sp = @issue.project.shared_agile_sprints.where(id: configured_params['issue']['sprint_id']).first
      (render_error_message(l(:label_agile_action_not_available)); return false) if configured_params['issue']['sprint_id'].present? && new_sp.nil?
      if old_sp != new_sp
        @issue.agile_data.agile_sprint = new_sp
        @issue.current_journal.details.build(property: 'attr', prop_key: 'agile_sprint', old_value: old_sp, value: new_sp)
      end
    end
    configured_params['issue'].delete('status_id') if configured_params['issue'] && configured_params['issue']['status_id'].blank?

    saved = configured_params['issue'] && configured_params['issue'].inject(true) do |total, attribute|
      if @issue.attributes.include?(attribute.first)
        total &&= @issue.attributes[attribute.first].to_i == attribute.last.to_i
      else
        total &&= true
      end
    end
    call_hook(:controller_agile_boards_update_before_save, { params: params, issue: @issue})
    @update = true
    @version_board = params[:version_board].to_i > 0
    if saved && @issue.save
      call_hook(:controller_agile_boards_update_after_save, { :params => params, :issue => @issue})
      AgileData.transaction do
        Issue.eager_load(:agile_data).find(params[:positions].keys).each do |issue|
          issue.agile_data.position = params[:positions][issue.id.to_s]['position']
          issue.agile_data.save
        end
      end if params[:positions]

      @inline_adding = params[:issue][:notes] || nil
      if Redmine::VERSION.to_s > '2.4'
        if current_status = @query.board_statuses.detect{ |st| st == @issue.status }
          @error_msg =  l(:lable_agile_wip_limit_exceeded) if current_status.over_wp_limit?
          @wp_class = current_status.wp_class
        end

        if @old_status = @query.board_statuses.detect{ |st| st == old_status }
          @wp_class_for_old_status = @old_status.wp_class
        end
      end

      respond_to do |format|
        format.html { render(:partial => 'issue_card', :locals => {:issue => @issue}, :status => :ok, :layout => nil) }
      end
    else
      respond_to do |format|
        messages = @issue.errors.full_messages
        messages = [l(:text_agile_move_not_possible)] if messages.empty?
        format.html {
          render json: messages, status: :unprocessable_entity, layout: nil
        }
      end
    end
  end
  def create_issue
    raise ::Unauthorized unless User.current.allowed_to?(:add_issues, @project) && params[:subject].present?

    @update = true
    @issue = Issue.new(:subject => params[:subject].strip, :project => @project,
                       :tracker => @project.trackers.first, :author => User.current, :status_id => params[:status_id])
    if params[:sprint_id].present? && User.current.allowed_to?(:manage_sprints, @project)
      @issue.agile_data.agile_sprint = @issue.project.shared_agile_sprints.where(id: params[:sprint_id]).first
    end
    begin
      if @issue.save(:validate => false)
        retrieve_agile_query_from_session
        if Redmine::VERSION.to_s > '2.4'
          if current_status = @query.board_statuses.detect{ |st| st == @issue.status }
            @error_msg =  l(:lable_agile_wip_limit_exceeded) if current_status.over_wp_limit?
            @wp_class = current_status.wp_class
          end
        end
        @not_in_scope = !@query.issues.include?(@issue)
        respond_to do |format|
          format.html { render(:partial => 'issue_card', :locals => {:issue => @issue}, :status => :ok, :layout => nil) }
        end
      else
        respond_to do |format|
          messages = @issue.errors.full_messages
          messages = [l(:text_agile_move_not_possible)] if messages.empty?
          format.html {
            render json: messages, status: :unprocessable_entity, layout: nil
          }
        end
      end
    rescue
      respond_to do |format|
        messages = @issue.errors.full_messages
        messages = [l(:text_agile_create_issue_error)] if messages.empty?
        format.html {
          render json: messages, status: :unprocessable_entity, layout: nil
        }
      end
    end
  end

  def edit_issue
    raise ::Unauthorized unless User.current.allowed_to?(:edit_issues, @project)
  end

  def update_issue
    raise ::Unauthorized unless User.current.allowed_to?(:edit_issues, @project)

    retrieve_agile_query_from_session
    return unless @issue.editable?
    @issue.safe_attributes = params[:issue].slice(:subject, :description)
    @issue.save
  end

  def backlog_load_more
    prepare_backlog_data

    render action: :load_more, layout: false
  end

  def backlog_autocomplete
    prepare_backlog_data

    render action: :autocomplete, layout: false
  end

  def issue_tooltip
    render :partial => 'issue_tooltip'
  end

  def inline_comment
    render 'inline_comment', :layout => nil
  end

  def agile_data
    @agile_data = @issue.agile_data
    return render_404 unless @agile_data

    respond_to do |format|
      format.any { head :ok }
      format.api { }
    end
  end

  private

  def configured_params
    return @configured_params if @configured_params

    issue_params = params[:issue]
    issue_params[:parent_issue_id] = issue_params[:parent_id] && issue_params.delete(:parent_id) if issue_params[:parent_id]
    issue_params[:assigned_to_id] = User.current.id if auto_assign_on_move?

    @configured_params = params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash : params
  end

  def auto_assign_on_move?
    RedmineAgile.auto_assign_on_move? && @issue.assigned_to.nil? &&
      !params[:issue].keys.include?('assigned_to_id') &&
      @issue.status_id != params[:issue]['status_id'].to_i
  end

  def statuses_allowed_for_create
    issue = Issue.new(project: @project)
    issue.tracker = issue_tracker(issue)
    issue.new_statuses_allowed_to
  end

  def issue_tracker(issue)
    return issue.allowed_target_trackers.first if issue.respond_to?(:allowed_target_trackers)
    return @project.trackers.first if @project
    nil
  end

  def render_error_message(message)
    render json: [message], status: :unprocessable_entity
  end
  def prepare_backlog_data
    retrieve_agile_query_from_session

    backlog_issues = @query.backlog_issues(params)
    paginator = @query.issues_paginator(backlog_issues, params[:page])
    @issues = backlog_issues.offset(paginator.offset).limit(paginator.per_page).all
    return unless paginator.next_page

    @more_url = backlog_load_more_agile_boards_path(project_id: @query.project.try(:id), q: params[:q], page: paginator.next_page)
  end
end
