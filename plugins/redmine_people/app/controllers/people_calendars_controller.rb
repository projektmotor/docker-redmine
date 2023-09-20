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

class PeopleCalendarsController < ApplicationController
  unloadable

  include PeopleHolidaysHelper
  include PeopleCalendarsHelper
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper

  def index
    raise Unauthorized unless User.current.allowed_people_to?(:view_people)

    if params[:year] && params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] && params[:month].to_i > 0 && params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= User.current.today.year
    @month ||= User.current.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)

    retrieve_people_holidays_query
    @query.group_by = nil
    if @query.valid?
      events = []
      events += @query.holidays(conditions: ['((start_date BETWEEN :from AND :to) OR (end_date BETWEEN :from AND :to))', from: @calendar.startdt, to: @calendar.enddt])
      events += @query.birthdays(month: @calendar.month) if show_birthdays?
      events += @query.dayoffs(conditions: ['((start_date BETWEEN :from AND :to) OR (end_date BETWEEN :from AND :to))', from: @calendar.startdt, to: @calendar.enddt])

      @calendar.custom_events = events
    end
  end
end
