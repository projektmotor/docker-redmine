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
    class CumulativeFlowChart < AgileChart
      def initialize(data_scope, options = {})
        @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
        @date_to = options[:date_to] || Date.today
        super data_scope, options
        @line_colors = { 0 => '255,204,0', 1 => '0,153,0', 2 => '80,122,170', 3 => '102,102,102', 4 => '154,167,208', 5 => '224,112,235',
                        6 => '235,17,142', 7 => '167,40,6', 8 => '108,97,58', 9 => '33,147,155', 10 => '43,237,59' }
      end

      def data
        datasets = []
        all_issues = @data_scope.eager_load(:journals => { :details => :journal })
        data = chart_dates_by_period.map do |date|
          issues = all_issues.select { |issue| issue.created_on.localtime.to_date <= date }
          issues.inject({}) do |accum, issue|
            status_details = issue.journals.map(&:details).flatten.select { |detail| 'status_id' == detail.prop_key }.sort_by { |a| a.journal.created_on }
            details_today_or_earlier = status_details.select { |a| a.journal.created_on.to_date <= date }
            last_status_change = details_today_or_earlier.last

            status = if last_status_change
                      last_status_change.value.to_i
                    elsif status_details.size > 0
                      status_details.first.old_value.to_i
                    else
                      issue.status_id
                    end

            accum[status] = accum[status].to_i + 1
            accum
          end
        end

        IssueStatus.where(:id => data.map(&:keys).flatten.uniq).sorted.reverse.each_with_index do |status, index|
          datasets << dataset(data.map { |d| d[status.id].to_i }, status.name, :color => line_colors[index], :fill => true, :nopoints => true) unless data.empty?
        end

        {
          :title    => l(:label_agile_charts_cumulative_flow),
          :y_title  => l(:label_agile_charts_number_of_issues),
          :labels   => @fields,
          :stacked  => true,
          :datasets => datasets
        }
      end

      private

      def available_statuses
        @available_statuses ||= IssueStatus.find(@data_scope.group("#{Issue.table_name}.status_id").count.keys).map
      end
    end
  end
end
