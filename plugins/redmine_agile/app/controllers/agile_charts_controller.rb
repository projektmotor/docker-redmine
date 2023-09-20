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

class AgileChartsController < ApplicationController
  unloadable

  menu_item :agile

  before_action :find_optional_project, :only => [:show, :render_chart]
  before_action :find_optional_version, :only => [:render_chart, :select_version_chart]

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

  def show
    retrieve_charts_query
    @query.date_to ||= Date.today
    @issues = @query.issues
    @agile_sprint = AgileSprint.where(id: @query.sprint_id).first if @query.sprint_id
    respond_to do |format|
      format.html
    end
  end

  def render_chart
    if @version
      @issues = @version.fixed_issues
      options = { date_from: @version.start_date,
                  date_to: [@version.due_date,
                            @issues.maximum(:due_date),
                            @issues.maximum(:updated_on)].compact.max,
                  due_date: @version.due_date || @issues.maximum(:due_date) || @issues.maximum(:updated_on),
                  chart_unit: params[:chart_unit] }
      @chart = params[:chart]
    else
      retrieve_charts_query
      @issues = Issue.visible
      @issues = @issues.eager_load(:agile_data) if @query.filters.has_key?('sprint_id')
      @issues = @issues.joins(:fixed_version) if @query.filters.keys.include?('version_status')
      @issues = @issues.where(@query.statement)
      options = { date_from: @query.date_from,
                  date_to: @query.date_to,
                  interval_size: @query.interval_size,
                  chart_unit: @query.chart_unit }
    end
    render_data(options)
  end

  def select_version_chart
  end

  private

  def render_data(options = {})
    agile_chart = RedmineAgile::Charts::Helper::AGILE_CHARTS[@chart]
    data = agile_chart[:class].data(@issues, options) if agile_chart

    if data
      data[:chart] = @chart
      data[:chart_unit] = options[:chart_unit]
      return render json: data
    end

    raise ActiveRecord::RecordNotFound
  end

  def find_optional_version
    @version = Version.find(params[:version_id]) if params[:version_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_charts_query
    if params[:query_id].present?
      @query = AgileChartsQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
    elsif params[:set_filter] || session[:agile_charts_query].nil? || session[:agile_charts_query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = AgileChartsQuery.new(:name => '_')
      @query.project = @project
      @query.build_from_params(params)
      session[:agile_charts_query] = { project_id: @query.project_id,
                                       filters: @query.filters,
                                       group_by: @query.group_by,
                                       column_names: @query.column_names,
                                       sprint_id: @query.sprint_id,
                                       date_from: @query.date_from,
                                       date_to: @query.date_to,
                                       interval_size: @query.interval_size,
                                       chart: @query.chart,
                                       chart_unit: @query.chart_unit }
    else
      # retrieve from session
      @query = AgileChartsQuery.new(name: '_',
                                    filters: session[:agile_charts_query][:filters] || session[:agile_query][:filters],
                                    group_by: session[:agile_charts_query][:group_by],
                                    column_names: session[:agile_charts_query][:column_names],
                                    sprint_id: session[:agile_charts_query][:sprint_id],
                                    date_from: session[:agile_charts_query][:date_from],
                                    date_to: session[:agile_charts_query][:date_to],
                                    interval_size: session[:agile_charts_query][:interval_size],
                                    chart: session[:agile_charts_query][:chart],
                                    chart_unit: session[:agile_charts_query][:chart_unit])
      @query.project = @project
    end
    @chart = params[:chart] || @query.chart
  end
end
