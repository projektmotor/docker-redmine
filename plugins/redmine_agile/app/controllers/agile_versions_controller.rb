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

class AgileVersionsController < ApplicationController
  unloadable

  menu_item :agile_backlog

  before_action :find_project_by_project_id
  before_action :authorize, except: [:autocomplete, :load_more]
  before_action :find_version, only: [:load_more]
  before_action :find_sprint, only: [:load_more]
  before_action :retrieve_query
  before_action :retrieve_data

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :issues
  include IssuesHelper
  helper :agile_boards
  include AgileBoardsHelper
  include RedmineAgile::Helpers::AgileHelper
  helper :agile_sprints
  include AgileSprintsHelper

  def index
    respond_to do |format|
      format.html
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sprints
    respond_to do |format|
      format.html
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def autocomplete
    @more_url = load_more_project_agile_versions_path(@project, { q: params[:q], page: @paginator.try(:next_page) }.merge(@object_params))
    render layout: false
  end

  def load_more
    @more_url = load_more_project_agile_versions_path(@project, { q: params[:q], page: @paginator.try(:next_page) }.merge(@object_params))
    render layout: false
  end

  private

  def sprint_request?
    params[:sprints] || action_name == 'sprints'
  end

  def retrieve_query
    if sprint_request?
      retrieve_versions_query(AgileSprintsQuery, :sprints_query)
    else
      retrieve_versions_query(AgileVersionsQuery, :versions_query)
    end
  end

  def retrieve_data
    if sprint_request?
      @tab_sprints = true
      @issues = @sprint ? find_sprint_issues : find_no_sprint_issues
      @object_params = { sprint_id: @sprint.try(:id), sprints: 1 }
    else
      @tab_versions = true
      @issues = @version ? find_version_issues : find_no_version_issues
      @object_params = { version_id: @version.try(:id) }
    end
  end

  def find_version
    return unless params[:version_id]
    @version = Version.visible.where(id: params[:version_id]).first
    return render_404 unless @version
  end

  def find_version_issues
    scope = @query.version_issues(@version)
    @paginator = @query.version_paginator(@version, params)
    @version_issues = scope.offset(@paginator.offset).limit(@paginator.per_page).all
  end

  def find_no_version_issues
    scope = @query.no_version_issues(params)
    @paginator = @query.version_paginator(nil, params)
    @no_version_issues = scope.offset(@paginator.offset).limit(@paginator.per_page).all
  end

  def find_sprint
    return unless params[:sprint_id]
    @sprint = @project.shared_agile_sprints.where(id: params[:sprint_id]).first
    return render_404 unless @sprint
  end

  def find_sprint_issues
    scope = @query.sprint_issues(@sprint)
    @paginator = @query.sprint_paginator(@sprint, params)
    @sprint_issues = scope.offset(@paginator.offset).limit(@paginator.per_page).all
  end

  def find_no_sprint_issues
    scope = @query.no_sprint_issues(params)
    @paginator = @query.sprint_paginator(nil, params)
    @no_sprint_issues = scope.offset(@paginator.offset).limit(@paginator.per_page).all
  end
end
