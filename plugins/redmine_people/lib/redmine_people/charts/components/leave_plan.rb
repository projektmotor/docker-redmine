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
      class LeavePlan < BaseComponent
        def initialize(user, dayoffs, date_from, date_to, scale = 1)
          @user = user
          @dayoffs = dayoffs

          editable = User.current.allowed_people_to?(:edit_leave)
          @dayoff_bars = @dayoffs.map do |dayoff|
            personal_editable =
              if dayoff.user_id == User.current.id
                editable || (User.current.allowed_people_to?(:edit_personal_leave) && !dayoff.approved)
              else
                editable
              end

            Components::DayoffBar.new(dayoff, date_from, date_to, personal_editable, scale)
          end
        end

        def render_subject
          content_tag(:div, class: 'user-subject') { person_tag(@user, only_path: true) }
        end

        def render_line
          content_tag :div, class: 'user-line' do
            @dayoff_bars.inject(''.html_safe) do |bar_html, dayoff_bar|
              bar_html + dayoff_bar.render
            end
          end
        end
      end
    end
  end
end
