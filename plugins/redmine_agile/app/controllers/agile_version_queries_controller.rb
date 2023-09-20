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

class AgileVersionQueriesController < ApplicationController
  helper :queries
  include QueriesHelper
  helper :agile_boards
  include AgileBoardsHelper

  before_action :find_optional_project
  before_action :find_query, except: [:new, :create]

  def new
    @query = AgileVersionsQuery.new
    @query.user = User.current
    @query.project = @project
    fill_version_query
  end

  def create
    @query = AgileVersionsQuery.new
    @query.user = User.current
    @query.project = @project
    fill_version_query
    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_agile_versions_board(query_id: @query)
    else
      render action: 'new', layout: !request.xhr?
    end
  end

  def edit; end

  def update
    fill_version_query
    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_agile_versions_board(query_id: @query)
    else
      render action: 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to_agile_versions_board(set_filter: 1)
  end

  private

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:manage_backlog, @project)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_query
    @query = AgileVersionsQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def fill_version_query
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_backlog, @project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || AgileQuery::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids] if Redmine::VERSION.to_s > '2.4'
    else
      @query.visibility = AgileQuery::VISIBILITY_PRIVATE
    end
    @query.column_names = nil if params[:default_columns]
  end

  def redirect_to_agile_versions_board(options)
    redirect_to project_agile_versions_path(options.merge(project_id: @project))
  end
end
