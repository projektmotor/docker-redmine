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
  module Charts
    class LeavePlannerChart < BaseGanttChart
      def initialize(dayoffs, date_from, date_to, group_by, options = {})
        super(date_from, date_to, options)
        @dayoffs = dayoffs
        @group_by = group_by
        @leave_plan_groups = build_leave_plan_groups(@dayoffs, @date_from, @date_to, @group_by)
      end

      def common_params
        { controller: 'dayoffs_controller', action: 'index' }
      end

      def params_previous
        common_params.merge(set_filter: 1, year: @date_from.year, month: @date_from.month)
      end

      def params_next
        common_params.merge(set_filter: 1, year: @date_to.year, month: @date_to.month)
      end

      def content_height
        [@leave_plan_groups.sum(&:lines_count) * line_height + 100, default_height].max # 100px for tooltips
      end

      def render_subjects
        @leave_plan_groups.inject(''.html_safe) do |subjects_html, leave_plan_group|
          subjects_html + leave_plan_group.render_subjects
        end
      end

      def render_lines
        @leave_plan_groups.inject(''.html_safe) do |lines_html, leave_plan_group|
          lines_html + leave_plan_group.render_lines
        end
      end

      private

      def build_leave_plan_groups(dayoffs, date_from, date_to, group_by)
        if group_by.present?
          grouped_dayoffs = dayoffs.group_by { |dayoff| dayoff.send(group_by) }
          grouped_dayoffs.inject([]) do |leave_plan_groups, (group_object, dayoffs)|
            leave_plan_groups << Components::LeavePlanGroup.new(group_object, group_by, dayoffs, date_from, date_to, column_width)
          end
        else
          [Components::LeavePlanGroup.new(nil, nil, dayoffs, date_from, date_to, column_width)]
        end
      end
    end
  end
end
