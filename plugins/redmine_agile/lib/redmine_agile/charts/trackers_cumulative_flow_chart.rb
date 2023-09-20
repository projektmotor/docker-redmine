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
    class TrackersCumulativeFlowChart < AgileChart
      def initialize(data_scope, options = {})
        @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
        @date_to = options[:date_to] || Date.today
        super data_scope, options
        @line_colors = { 0 => '0,153,0', 1 => '80,122,170', 2 => '102,102,102', 3 => '255,204,0', 4 => '154,167,208', 5 => '224,112,235',
                        6 => '235,17,142', 7 => '167,40,6', 8 => '108,97,58', 9 => '33,147,155', 10 => '43,237,59' }
      end

      def data
        datasets = []
        Tracker.where(:id => @data_scope.group("#{Issue.table_name}.tracker_id").count.keys).sorted.reverse.each_with_index do |tracker, index|
          created_by_date = @data_scope.where(:tracker_id => tracker.id).
                            where("#{Issue.table_name}.created_on >= ?", @date_from).
                            where("#{Issue.table_name}.created_on <= ?", @date_to).
                            where("#{Issue.table_name}.created_on IS NOT NULL").
                            group("#{Issue.table_name}.created_on").
                            count
          created_by_period = issues_count_by_period(created_by_date)
          total_issues = @data_scope.where(:tracker_id => tracker.id).
                        where("#{Issue.table_name}.created_on < ?", @date_from).count
          cumulative_created_by_period = created_by_period.map { |x| total_issues += x }

          datasets << dataset(cumulative_created_by_period, tracker.name, :color => line_colors[index], :fill => true, :nopoints => true) if created_by_period.any?
        end

        {
          :title    => l(:label_agile_charts_cumulative_flow),
          :y_title  => l(:label_agile_charts_number_of_issues),
          :stacked  => true,
          :labels   => @fields,
          :datasets => datasets
        }
      end
    end
  end
end
