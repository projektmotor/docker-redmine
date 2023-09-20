# encoding: utf-8
#
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

module PeopleHolidaysHelper
  include PeopleHelper
  include DepartmentsHelper

  def retrieve_people_holidays_query
    if params[:query_id].present?
      @query = PeopleHolidayQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      session[:people_holidays_query] = {:id => @query.id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:people_holidays_query].nil?
      # Give it a name, required to be valid
      @query = PeopleHolidayQuery.new(:name => "_")
      @query.build_from_params(params)
      session[:people_holidays_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = PeopleHolidayQuery.find(session[:people_holidays_query][:id]) if session[:people_holidays_query][:id]
      @query ||= PeopleHolidayQuery.new(:name => "_", :filters => session[:people_holidays_query][:filters], :group_by => session[:people_holidays_query][:group_by], :column_names => session[:people_holidays_query][:column_names])
    end
  end

  def notify_options_for_select
    selected = params[:holiday][:notify] rescue ''
    options_for_select([['', ''], [l('label_all').humanize, 'all']], selected) << department_tree_grouped_options_for_select(Department.all_visible_departments, :selected => selected.to_i)
  end
end
