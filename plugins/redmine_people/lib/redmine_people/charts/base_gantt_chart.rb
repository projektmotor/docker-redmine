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
    class BaseGanttChart < Components::BaseComponent
      DEFAULT_OPTIONS = {
        column_width: 30, # px
        subject_width: 330, # px
        line_height: 32, # height: 16px + padding-top: 8px + padding-bottom: 8px
        header_height: 18, # px
        headers_height: 36, # 2 * header_height px
        default_height: 206 # px
      }.freeze

      attr_reader :date_from, :date_to

      def initialize(date_from, date_to, options = {})
        @date_from = date_from
        @date_to = date_to
        @options = DEFAULT_OPTIONS.merge(options)
        @today = User.current.today
        @calendar = Redmine::Helpers::Calendar.new(@today)
        @calendar.custom_events = PeopleHoliday.between(@date_from, @date_to).to_a
      end

      DEFAULT_OPTIONS.keys.each do |key|
        define_method(key) { @options[key] }
      end

      def params_previous
        raise NotImplementedError
      end

      def params_next
        raise NotImplementedError
      end

      def content_height
        raise NotImplementedError
      end

      def height
        @height ||= content_height + headers_height
      end

      def width
        ((@date_to - @date_from + 1) * column_width).to_i
      end

      def subjects_column_styles
        style = 'padding: 0;'
        style << "width: #{subject_width}px;"
        style
      end

      def subjects_container_styles
        style = 'position: relative;'
        style << "height: #{height + 24}px;"
        style << "width: #{subject_width + 1}px;"
        style
      end

      def subjects_header_styles
        style = 'right: -2px;'
        style << 'background: #eee;'
        style << "height: #{headers_height}px;"
        style << "width: #{subject_width}px;"
        style
      end

      def subjects_column_borders_styles
        style = 'right: -2px;'
        style << 'border-left: 1px solid #c0c0c0;'
        style << 'overflow: hidden;'
        style << "height: #{height}px;"
        style << "width: #{subject_width}px;"
        style
      end

      def subjects_content_styles
        style = 'position: relative;'
        style << 'right: -2px;'
        style << "top: #{headers_height + 1}px;"
        style
      end

      def gantt_area_styles
        style = 'position: relative; overflow-x: auto; overflow-y: hidden;'
        style << "height: #{height + 24}px;"
        style
      end

      def lines_header_styles
        style = 'background: #eee;'
        style << "height: #{headers_height}px;"
        style << "width: #{width - 1}px;"
        style
      end

      def lines_container_styles
        style = 'position:absolute;'
        style << "top: #{headers_height + 1}px;"
        style << "width: #{width - 1}px;"
        style
      end

      def render_subjects
        raise NotImplementedError
      end

      def render_lines
        raise NotImplementedError
      end

      def render_week_header(left, height, width, from, to)
        style = "left: #{left}px;"
        style += "height: #{height}px;"
        style += "width: #{width}px;"
        content_tag(:div, style: style, class: 'gantt_hdr') do
          content_tag(:small) do
            dates_range_label(from, to) if width >= column_width * 3 - 1
          end
        end
      end

      def render_weeks_headers
        output = ''.html_safe
        left = 0
        height = header_height
        if @date_from.cwday == 1
          # @date_from is monday
          week_f = @date_from
        else
          # find next monday after @date_from
          week_f = @date_from + (7 - @date_from.cwday + 1)
          width = (7 - @date_from.cwday + 1) * column_width - 1
          from = @date_from
          to = from.next_day(7 - from.cwday)
          output << render_week_header(left, height, width, from, to)

          left = left + width + 1
        end

        while week_f <= @date_to
          width = ((week_f + 6 <= @date_to) ?
                     7 * column_width - 1 :
                     (@date_to - week_f + 1) * column_width - 1).to_i

          last_day_of_week = week_f.next_day(6)
          last_day = last_day_of_week > @date_to ? @date_to : last_day_of_week
          output << render_week_header(left, height, width, week_f, last_day)

          left = left + width + 1
          week_f = week_f + 7
        end

        output
      end

      def render_day_numbers_headers
        left = 0
        top = header_height + 1
        height = content_height + header_height - 1
        wday = @date_from.cwday
        day_num = @date_from

        output = ''.html_safe
        (@date_to - @date_from + 1).to_i.times do
          width = column_width - 1
          style = "left:#{left}px;"
          style << "top:#{top}px;"
          style << "width:#{width}px;"
          style << "height:#{height}px;"
          style << 'font-size:0.8em;'

          if @calendar.holiday?(day_num) && !@calendar.weekend?(day_num)
            style << 'background-color: rgb(255, 232, 232); color: rgb(154, 93, 93);'
          end

          css_class = 'gantt_hdr'
          css_class << ' nwday' if non_working_week_days.include?(wday)

          output << content_tag(:div, style: style, class: css_class) { day_num.day.to_s }

          left = left + width + 1
          day_num += 1
          wday += 1
          wday = 1 if wday > 7
        end
        output
      end

      def render_today_line
        if @today.between?(@date_from, @date_to)
          today_left = (((@today - @date_from + 1) * column_width).floor - 1).to_i
          style = 'position: absolute;'
          style += "height: #{content_height}px;"
          style += "top: #{headers_height + 1}px;"
          style += "left: #{today_left}px;"
          style += "width:10px;"
          style += "border-left: 1px dashed red;"
          content_tag(:div, '&nbsp;'.html_safe, style: style, id: 'today_line')
        end
      end
    end
  end
end
