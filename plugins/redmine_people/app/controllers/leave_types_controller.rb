# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class LeaveTypesController < ApplicationController
  # </PRO>
  before_action :require_admin
  before_action :find_leave_type, only: [:edit, :update, :destroy]

  def new
    @leave_type = LeaveType.new
  end

  def create
    @leave_type = LeaveType.new
    @leave_type.safe_attributes = params[:leave_type]

    if @leave_type.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to people_settings_path(tab: 'leave_types')
    else
      render :new
    end
  end

  def edit
  end

  def update
    @leave_type.safe_attributes = params[:leave_type]
    if @leave_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to people_settings_path(tab: 'leave_types')
    else
      render :edit
    end
  end

  def destroy
    if @leave_type.destroy
      flash[:notice] = l(:notice_leave_type_successfully_destroyed)
    else
      flash[:error] = @leave_type.errors.full_messages.first
    end

  rescue Exception => e
    flash[:error] = e.message
  ensure
    redirect_to people_settings_path(tab: 'leave_types')
  end

  private

  def find_leave_type
    @leave_type = LeaveType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  # </PRO>
end
