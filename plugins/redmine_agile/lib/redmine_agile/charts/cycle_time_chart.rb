# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module RedmineAgile
  module Charts
    class CycleTimeChart < AgileChart
      def initialize(data_scope, options = {})
        @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
        @date_to = options[:date_to] || Date.today
        @average_lead_time = !!options[:average_lead_time]
        super data_scope, options
      end

      def data
        { title: l(:label_agile_charts_lead_time),
          y_title: l(:label_agile_charts_number_of_days),
          labels: @fields,
          type: 'scatter',
          datasets: bubbles_datasets + [moving_average_line_dataset] + standard_deviation_area_datasets }
      end

      private

      def round_to_even_decimal(number)
        int_value = (number * 10).to_i
        float_value = int_value.fdiv(10)
        int_value.even? ? float_value : (float_value + 0.1).round(1)
      end

      def calculate_lead_time(issue)
        [round_to_even_decimal((issue.closed_on.to_time - issue.created_on.to_time).to_f / 1.day.seconds), 0.2].max
      end

      def lead_times
        @lead_times ||= closed_issues.map do |issue|
          { tracker: issue.tracker,
            closed_on: issue.closed_on,
            lead_time: calculate_lead_time(issue) }
        end
      end

      def lead_times_by_period
        @lead_times_by_period ||= lead_times.inject({}) do |h, data|
          next if data[:closed_on].to_date > @date_to.to_date
          period_num = (@date_to.to_date - data[:closed_on].to_date).to_i / scale_division
          h[period_num] = [] if h[period_num].blank?
          h[period_num] << data
          h
        end
      end

      def mixed_tracker
        @mixed_tracker ||= Tracker.new(
          name: l(:label_agile_mixed_trackers),
          position: Tracker.maximum(:position).to_i + 1,
          color: 'dimgray'
        )
      end

      def tracker_by(lead_times)
        trackers = lead_times.map { |data| data[:tracker] }.uniq
        trackers.size > 1 ? mixed_tracker : trackers.first
      end

      def bubbles_data
        @bubbles_data ||= begin
          data = {}
          (0..period_count - 1).each do |period_num|
            next if lead_times_by_period[period_num].blank?

            lead_time_groups = lead_times_by_period[period_num].group_by { |h| h[:lead_time] }
            lead_time_groups.each do |lead_time_value, lead_times|
              tracker = tracker_by(lead_times)
              data[tracker] = [] unless data[tracker]
              data[tracker] << {
                x: period_count - period_num - 1,
                y: lead_time_value,
                r: lead_times.size > 1 ? 4 : 2 # px
              }
            end
          end

          data
        end
      end

      def bubbles_datasets
        @bubbles_datasets ||= bubbles_data.keys.sort.map do |tracker|
          { type: 'bubble',
            label: tracker.to_s,
            data: bubbles_data[tracker],
            backgroundColor: tracker.color }
        end
      end

      def average(list)
        list.sum.fdiv(list.size).round(2)
      end

      def average_lead_times
        @average_lead_times ||=
          lead_times_by_period.inject([0] * period_count) do |values, (period_num, lead_times)|
            values[period_num] = average(lead_times.map { |data| data[:lead_time] })
            values
          end.drop_while { |value| value == 0 }.reverse!
      end

      def moving_average_line_data
        @moving_average_line_data ||= begin
          values = average_lead_times.dup
          prev_value = values[0]

          values.each_with_index do |value, index|
            values[index] = value == 0 ? prev_value : average([value, prev_value])
            prev_value = values[index]
          end

          values.map.with_index { |value, index| { x: index, y: value } }
        end
      end

      def moving_average_line_dataset
        { type: 'line',
          data: moving_average_line_data,
          label: l(:label_agile_moving_average),
          borderColor: 'black',
          borderWidth: 2,
          pointRadius: 2,
          fill: false }
      end

      def variance(list)
        return 0 if list.size < 2
        mean = average(list)
        list.sum { |x| (x - mean) ** 2 }.fdiv(list.size - 1)
      end

      def standard_deviation(list)
        Math.sqrt variance(list)
      end

      def standard_deviation_list
        @standard_deviation_list ||= begin
          values = [0] * period_count

          values.each_index do |index|
            list = lead_times_by_period[index].to_a.map { |data| data[:lead_time] }
            sd = standard_deviation(list)
            values[index] = (sd != 0 || index == 0) ? sd : values[index - 1]
          end

          values.last(average_lead_times.size).reverse!
        end
      end

      def standard_deviation_line_data(position = :top)
        sign = position == :top ? 1 : -1
        moving_average_line_data.map do |item|
          { x: item[:x], y: item[:y] + sign * standard_deviation_list[item[:x]] }
        end
      end

      def standard_deviation_line_dataset(position = :top)
        { type: 'line',
          data: standard_deviation_line_data(position),
          borderWidth: 0.1,
          pointRadius: 0,
          pointHoverRadius: 0,
          fill: position == :top ? '+1' : '-1',
          lineTension: 0.4,
          spanGaps: true }
      end

      def standard_deviation_area_datasets
        [standard_deviation_line_dataset(:top), standard_deviation_line_dataset(:bottom)]
      end

      def closed_issues
        @closed_issues ||=
          @data_scope
            .includes(:tracker)
            .open(false)
            .where("#{Issue.table_name}.closed_on IS NOT NULL")
            .where("#{Issue.table_name}.closed_on >= ?", @date_from)
            .where("#{Issue.table_name}.closed_on < ?", @date_to + 1)
            .where("#{Issue.table_name}.created_on IS NOT NULL")
      end
    end
  end
end
