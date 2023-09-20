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

module RedminePeople
  module Patches
    module CalendarPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        # Sets calendar events
        def custom_events=(events)
          set_custom_events(events, true)
        end

        def set_custom_events(events, only_for_current_year = false)
          @events = events
          multiply_events

          @ending_events_by_days = @events.group_by do |event|
            only_for_current_year && event.due_date && event.due_date < Date.today ? current_year_date(event.due_date) : event.due_date
          end

          @starting_events_by_days = @events.group_by do |event|
            only_for_current_year && event.start_date < Date.today ? current_year_date(event.start_date) : event.start_date
          end
        end

        def weekend?(day)
          Setting.non_working_week_days.include? day.cwday.to_s
        end

        def holiday?(day)
          is_holiday = false
          events_on(day).each do |e|
            if e.is_a? PeopleHoliday
              return false if e.is_workday
              is_holiday = true
            end
          end
          weekend?(day) || is_holiday
        end

        private

        def multiply_events
          events = @events.dup
          events.each do |event|
            return if event.due_date.blank? || event.start_date.blank?
            if event.due_date > event.start_date
              date = event.start_date + 1
              while date < event.due_date
                e = event.dup
                e.start_date = date
                e.due_date = nil
                @events.push(e)
                date = date + 1
              end
            end
          end
        end

        def current_year_date(date)
          return if date.blank?
          year = @date.year
          mmdd = date.strftime('%m%d')
          mmdd = '0301' if mmdd == '0229' && !Date.parse("#{year}0101").leap?
          Date.parse("#{year}#{mmdd}")
        end
      end
    end
  end
end

unless Redmine::Helpers::Calendar.included_modules.include?(RedminePeople::Patches::CalendarPatch)
  Redmine::Helpers::Calendar.send(:include, RedminePeople::Patches::CalendarPatch)
end
