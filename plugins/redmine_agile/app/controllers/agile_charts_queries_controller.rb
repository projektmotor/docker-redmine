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

class AgileChartsQueriesController < ApplicationController
  menu_item :agile

  before_action :find_query, except: [:index, :new, :create]
  before_action :find_optional_project, only: [:new, :create]

  helper :queries

  def new
    @query = AgileChartsQuery.new
    @query.user = User.current
    @query.project = @project
    @chart = params[:chart] || 'issues_burndown'
    unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.visibility = AgileChartsQuery::VISIBILITY_PRIVATE
    end
    @query.build_from_params(params)
  end

  def create
    @query = AgileChartsQuery.new
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || AgileChartsQuery::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids] if Redmine::VERSION.to_s > '2.4'
    else
      @query.visibility = AgileChartsQuery::VISIBILITY_PRIVATE
    end

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_agile_chart(query_id: @query)
    else
      render action: 'new', layout: !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.project = nil if params[:query_is_for_all]
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || AgileChartsQuery::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids] if Redmine::VERSION.to_s > '2.4'
    else
      @query.visibility = AgileChartsQuery::VISIBILITY_PRIVATE
    end

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_agile_chart query_id: @query
    else
      render action: 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to_agile_chart set_filter: 1
  end

private
  def find_query
    @query = AgileChartsQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:add_agile_queries, @project, global: true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_agile_chart(options)
    options[:project_id] = @project if @project
    redirect_to agile_charts_path(options)
  end
end
