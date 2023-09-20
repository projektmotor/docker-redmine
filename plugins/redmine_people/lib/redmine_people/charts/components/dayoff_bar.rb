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
      class DayoffBar < BaseComponent
        def initialize(dayoff, date_from, date_to, editable, scale = 1)
          @dayoff = dayoff
          @date_from = date_from
          @date_to = date_to
          @editable = editable
          @scale = scale
        end

        def render
          coords = coordinates(@dayoff.start_date, @dayoff.due_date)
          if coords[:bar_start] && coords[:bar_end]
            render_bar(coords) + render_tooltip(coords)
          end
        end

        private

        def render_bar(coords)
          style = "left: #{coords[:bar_start]}px;"
          style << "height: 7px;" if @dayoff.hours_per_day
          style << "width: #{coords[:bar_end] - coords[:bar_start] - 2}px;"
          style << 'border: 1px solid #f66;' unless @dayoff.is_approved?
          content_tag(:div, '&nbsp;'.html_safe, style: style, class: css_classes)
        end

        def css_classes
          "dayoff-bar #{@dayoff.color}"
        end

        def tooltip_styles(coords)
          style = 'position: absolute;'
          style << "left:#{coords[:bar_start]}px;"
          style << "height: 7px;" if @dayoff.hours_per_day
          style << "width: #{coords[:bar_end] - coords[:bar_start]}px;"
          style
        end

        def tooltip_content_styles
          style = @dayoff.hours_per_day ? 'top: 7px;' : ''
          style << 'border: 1px solid #f66;' unless @dayoff.is_approved?
          style
        end

        def render_tooltip(coords)
          content_tag(:div, style: tooltip_styles(coords), class: "tooltip #{'editable' if @editable}", edit_url: edit_dayoff_path(@dayoff)) do
            content_tag(:span, style: tooltip_content_styles, class: 'tip') do
              render_attributes(tooltip_dayoff_attributes(@dayoff), true)
            end
          end
        end

        def coordinates(start_date, end_date)
          coords = {}
          if start_date && end_date && start_date <= @date_to && end_date >= @date_from
            if start_date >= @date_from
              coords[:bar_start] = start_date - @date_from
            else
              coords[:bar_start] = 0
            end
            if end_date <= @date_to
              coords[:bar_end] = end_date - @date_from + 1
            else
              coords[:bar_end] = @date_to - @date_from + 1
            end
          end

          coords.each { |key, value| coords[key] = to_pixel(value) }
          coords
        end

        def to_pixel(value)
          (value * @scale).floor
        end
      end
    end
  end
end
