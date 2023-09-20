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
    class BurnupChart < AgileChart
      def initialize(data_scope, options = {})
        @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
        @date_to = (options[:date_to] || Date.today).to_date
        @due_date = options[:due_date].to_date if options[:due_date]

        super data_scope, options

        @fields = [''] + @fields
        @y_title = l(:label_agile_charts_number_of_issues)
        @graph_title = l(:label_agile_charts_burnup)
        @line_colors = { :created => '102,102,102', :closed => '80,122,170', :ideal => '102,102,102' }
      end

      def data
        return false unless calculate_data.any?

        datasets = [
          dataset(@cumulative_data, l(:field_created_on),:fill => true, :color => line_colors[:created]),
          dataset(@data, l(:field_closed_on), :fill => true, :color => line_colors[:closed]),
          dataset(ideal_effort(@data.first, @cumulative_data.last), l(:label_agile_ideal_work_remaining), :color => line_colors[:ideal], :dashed => true, :nopoints => true)
        ]

        {
          :title    => @graph_title,
          :y_title  => @y_title,
          :labels   => @fields,
          :datasets => datasets,
          :show_tooltips => [0, 1]
        }
      end

      def self.data(data_scope, options = {})
        if options[:chart_unit] == Helper::UNIT_HOURS
          WorkBurnupChart.new(data_scope, options.merge(estimated_unit: ESTIMATE_HOURS)).data
        elsif options[:chart_unit] == Helper::UNIT_STORY_POINTS
          WorkBurnupChart.new(data_scope, options.merge(estimated_unit: ESTIMATE_STORY_POINTS)).data
        else
          super
        end
      end

      protected

      def ideal_effort(start_data, end_data)
        data = [0] * (due_date_period - 1)
        active_periods = (RedmineAgile.exclude_weekends? && date_short_period?) ? due_date_period - @weekend_periods.select { |p| p < due_date_period }.count : due_date_period
        avg_remaining_velocity = (end_data - start_data).to_f / active_periods.to_f
        sum = start_data.to_f
        data[0] = sum
        (1..due_date_period - 1).each do |i|
          sum += avg_remaining_velocity unless (RedmineAgile.exclude_weekends? && date_short_period?) && @weekend_periods.include?(i - 1)
          data[i] = (sum * 100).round / 100.0
        end
        data[due_date_period] = end_data
        data
      end

      def calculate_data
        created_by_period = issues_count_by_period(scope_by_created_date)
        closed_by_period = issues_count_by_period(scope_by_closed_date)

        total_issues = @data_scope.where("#{Issue.table_name}.created_on < ?", @date_from).count
        total_closed = @data_scope.open(false).where("#{Issue.table_name}.closed_on < ?", @date_from).count

        sum = total_issues
        @cumulative_data = [total_issues] + created_by_period.first(current_date_period).map { |x| sum += x }
        sum = total_closed
        @data = [total_closed] + closed_by_period.first(current_date_period).map { |x| sum += x }
      end
    end
  end
end
