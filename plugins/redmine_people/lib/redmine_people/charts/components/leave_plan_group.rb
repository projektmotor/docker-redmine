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
    module Components
      class LeavePlanGroup < BaseComponent
        def initialize(group_object, group_by, dayoffs, date_from, date_to, scale = 1)
          @group_object = group_object
          @group_by = group_by
          @leave_plans = build_leave_plans(dayoffs, date_from, date_to, scale)
        end

        def lines_count
          @lines_count ||= @group_by ? @leave_plans.size + 1 : @leave_plans.size
        end

        def render_subjects
          if @group_by
            content_tag(:div, group_id: "#{@group_object.try(:id)}", class: "group-container open") do
              render_group_subject +
                content_tag(:div, class: 'group') { render_leave_plan_subjects }
            end
          else
            render_leave_plan_subjects
          end
        end

        def render_lines
          if @group_by
            content_tag(:div, group_id: "#{@group_object.try(:id)}", class: "group-container open") do
              render_group_line +
                content_tag(:div, class: 'group') { render_leave_plan_lines }
            end
          else
            render_leave_plan_lines
          end
        end

        private

        def render_leave_plan_subjects
          @leave_plans.inject(''.html_safe) do |subjects_html, leave_plan|
            subjects_html + leave_plan.render_subject
          end
        end

        def render_leave_plan_lines
          @leave_plans.inject(''.html_safe) do |subjects_html, leave_plan|
            subjects_html + leave_plan.render_line
          end
        end

        def render_group_subject
          group_name = @group_object ? format_object(@group_object) : "(#{l(:label_blank_value)})"

          content_tag :div, id: "group_#{@group_object.try(:id)}", class: 'group-subject' do
            [content_tag(:span, '&nbsp;'.html_safe, class: 'expander', onclick: %($('.group-container[group_id="#{@group_object.try(:id)}"]').toggleClass('open');)),
             group_name].join(' ').html_safe
          end
        end

        def render_group_line
          content_tag :div, '', id: "group_#{@group_object.try(:id)}", class: 'group-line'
        end

        def build_leave_plans(dayoffs, date_from, date_to, scale)
          dayoffs.group_by(&:user).inject([]) do |leave_plans, (user, dayoffs)|
            leave_plans << Components::LeavePlan.new(user, dayoffs, date_from, date_to, scale)
          end
        end
      end
    end
  end
end
