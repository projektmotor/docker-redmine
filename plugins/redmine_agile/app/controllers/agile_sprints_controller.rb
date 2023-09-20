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

class AgileSprintsController < ApplicationController
  helper :agile_sprints
  include AgileSprintsHelper

  before_action :find_optional_project, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :find_optional_project_for_show_action, only: :show
  before_action :find_agile_sprint, only: [:show, :edit, :update, :destroy]

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @sprints = @project.agile_sprints
  end

  def show
    issues = @agile_sprint.issues.includes(:time_entries)
    @estimated_hours = issues.map(&:estimated_hours).compact.sum
    @spent_hours = issues.map(&:spent_hours).compact.sum
    @story_points = issues.map(&:story_points).compact.sum
    all_done_ratio = issues.map(&:done_ratio)
    @done_ratio = all_done_ratio.sum / all_done_ratio.size.to_f
  end

  def new
    @agile_sprint = @project.agile_sprints.build(initial_agile_sprint_params)
  end

  def create
    @agile_sprint = @project.agile_sprints.build
    @agile_sprint.safe_attributes = params[:agile_sprint]
    if @agile_sprint.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api  { render :action => 'show', :status => :created }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.api  { render_validation_errors(@agile_sprint) }
      end
    end
  end

  def edit
  end

  def update
    @agile_sprint.safe_attributes = params[:agile_sprint]
    if @agile_sprint.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api  { redirect_to :action => 'show', :id => @agile_sprint }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.api  { render_validation_errors(@agile_sprint) }
      end
    end
  end

  def destroy
    @agile_sprint.destroy
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api { head :ok }
    end
  end

  def get_story_points
    @story_points = {}
    unless params[:sprint_ids].empty?
      @story_points = AgileSprint.where(id: params[:sprint_ids]).joins(:issues).group('agile_sprints.id').sum(:story_points)
    end
    respond_to do |format|
      format.json { render json: (@story_points || { respond: 'OK' }) }
    end
  end

  def get_story_points
    @story_points = {}
    unless params[:sprint_ids].empty?
      @story_points = AgileSprint.where(id: params[:sprint_ids]).joins(:issues).group('agile_sprints.id').sum(:story_points)
    end
    respond_to do |format|
      format.json { render json: (@story_points || { respond: 'OK' }) }
    end
  end

  private

  def initial_agile_sprint_params
    last_sprint = @project.agile_sprints.last
    {
      name: last_sprint ? last_sprint.name.gsub(/(\d+)/) { $&.to_i + 1 } : '',
      start_date: workday_for(Date.today)
    }
  end

  def workday_for(date)
    return date + 1 if date.instance_eval { sunday? }
    return date + 2 if date.instance_eval { saturday? }
    date
  end

  def find_optional_project_for_show_action
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:manage_backlog, @project)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_agile_sprint
    @agile_sprint = @project.agile_sprints.where(id: params[:id]).first
    return render_404 unless @agile_sprint
  end

  def redirect_to_settings_in_projects
    redirect_back_or_default settings_project_path(@project, :tab => 'agile_sprints')
  end
end
