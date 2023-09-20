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

class PeopleHolidaysController < ApplicationController
  unloadable

  before_action :check_permissions, :except => [:index]
  before_action :find_holiday, :except => [:index, :new, :create]

  def index
    raise Unauthorized unless User.current.allowed_people_to?(:view_people)
    @people_holidays = PeopleHoliday.order('start_date DESC')
  end

  def new
    @holiday = PeopleHoliday.new
  end

  def edit
  end

  def create
    @holiday = PeopleHoliday.new
    @holiday.safe_attributes = params[:holiday]
    if @holiday.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to people_holidays_path
        }
      end
    else
      respond_to do |format|
        format.html {
          render :action => 'new'
        }
      end
    end
  end

  def update
    @holiday.safe_attributes = params[:holiday]
    if @holiday.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to people_holidays_path }
      end
    else
      respond_to do |format|
        format.html { render 'edit', :id => @holiday }
      end
    end
  end

  def destroy
    @holiday.destroy
    respond_to do |format|
      format.html { redirect_to people_holidays_path }
    end
  end

  private

  def check_permissions
    raise Unauthorized unless User.current.allowed_people_to?(:manage_calendar)
  end

  def find_holiday
    @holiday = PeopleHoliday.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
