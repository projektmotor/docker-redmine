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

class PeopleHolidayQuery < Query
  self.queried_class = PeopleHoliday

  self.available_columns = [
    QueryColumn.new(:name, :sortable => "#{PeopleHoliday.table_name}.name", :caption => :label_people_holiday_name),
    QueryColumn.new(:start_date, :sortable => "#{PeopleHoliday.table_name}.start_date", :caption => :label_people_holiday_start_date),
    QueryColumn.new(:end_date, :sortable => "#{PeopleHoliday.table_name}.end_date", :caption => :label_people_holiday_end_date)
  ]

  def initialize(attributes = nil, *_args)
    super attributes
    self.filters ||= { 'status_id' => { :operator => 'o', :values => [''] } }
  end

  def initialize_available_filters
    add_available_filter 'name', :type => :string, :order => 0
    add_available_filter 'start_date', :type => :date_past, :order => 1
    add_available_filter 'end_date', :type => :date_past, :order => 2
  end

  # Returns people holidays
  # Valid options are :conditions
  def holidays(options = {})
    PeopleHoliday.where(options[:conditions]).to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns people birthdays
  # Valid options are :month
  def birthdays(options = {})
    PeopleInformation.where(birthday_condition(options[:month])).to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def dayoffs(options)
    Dayoff.where(options[:conditions]).to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  private

  def birthday_condition(month)
    if (ActiveRecord::Base.connection.adapter_name =~ /sqlite/i).present?
      ["CAST(strftime('%m', birthday) as INT) = ?", month]
    elsif (ActiveRecord::Base.connection.adapter_name =~ /SQLServer/i).present?
      ["MONTH(birthday) = ?", month]
    else
      ['extract(month from birthday) = ?', month]
    end
  end
end
