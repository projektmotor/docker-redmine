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
    class WorkVelocityChart < VelocityChart
      def initialize(data_scope, options = {})
        super data_scope, options

        if @estimated_unit == 'hours'
          @y_title = l(:label_agile_charts_number_of_hours)
        else
          @y_title = l(:label_agile_charts_number_of_story_points)
        end

        @line_colors = { :closed => '102,102,102', :created => '80,122,170'}
      end

      protected

      def calculate_velocity_data
        @data_scope = @data_scope.where("#{Issue.table_name}.rgt - #{Issue.table_name}.lft = 1") if use_subissue_done_ratio && @estimated_unit == 'hours'

        if @estimated_unit == 'hours'
          @created_by_period = issues_avg_count_by_period(hours_created)
          @closed_by_period = [issues_avg_count_by_period(hours_closed), issues_avg_count_by_period(hours_partially_closed)].
              transpose.map{ |hour| hour.reduce(:+) }
        else
          sp_formatted_values = {}
          sp_partially_closed.each{|k, v| sp_formatted_values[k] = v.to_f}
          @created_by_period = issues_avg_count_by_period(sp_created)
          @closed_by_period = [issues_avg_count_by_period(sp_closed), issues_avg_count_by_period(sp_formatted_values)].
              transpose.map{ |sp| sp.reduce(:+) }
        end
      end

      def hours_created
        @data_scope.
            where("#{Issue.table_name}.created_on >= ?", @date_from).
            where("#{Issue.table_name}.created_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.created_on IS NOT NULL").
            where("#{Issue.table_name}.estimated_hours IS NOT NULL").
            group("#{Issue.table_name}.created_on").
            sum("#{Issue.table_name}.estimated_hours")
      end

      def hours_closed
        @data_scope.
            open(false).
            where("#{Issue.table_name}.closed_on >= ?", @date_from).
            where("#{Issue.table_name}.closed_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.closed_on IS NOT NULL").
            where("#{Issue.table_name}.estimated_hours IS NOT NULL").
            group("#{Issue.table_name}.closed_on").
            sum("#{Issue.table_name}.estimated_hours")
      end

      def hours_partially_closed
        @data_scope.
            open(true).
            where("#{Issue.table_name}.created_on >= ?", @date_from).
            where("#{Issue.table_name}.created_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.created_on IS NOT NULL").
            where("#{Issue.table_name}.estimated_hours IS NOT NULL").
            where("#{Issue.table_name}.done_ratio > 0").
            group("#{Issue.table_name}.created_on").
            sum("(#{Issue.table_name}.estimated_hours * (#{Issue.table_name}.done_ratio) / 100)")
      end

      def sp_created
        @data_scope.
            where("#{Issue.table_name}.created_on >= ?", @date_from).
            where("#{Issue.table_name}.created_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.created_on IS NOT NULL").
            where("#{AgileData.table_name}.story_points IS NOT NULL").
            joins(:agile_data).
            group("#{Issue.table_name}.created_on").
            sum("#{AgileData.table_name}.story_points")
      end

      def sp_closed
        @data_scope.
            open(false).
            where("#{Issue.table_name}.closed_on >= ?", @date_from).
            where("#{Issue.table_name}.closed_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.closed_on IS NOT NULL").
            where("#{AgileData.table_name}.story_points IS NOT NULL").
            joins(:agile_data).
            group("#{Issue.table_name}.closed_on").
            sum("#{AgileData.table_name}.story_points")
      end

      def sp_partially_closed
        @data_scope.
            open(true).
            where("#{Issue.table_name}.created_on >= ?", @date_from).
            where("#{Issue.table_name}.created_on < ?", @date_to.to_date + 1).
            where("#{Issue.table_name}.created_on IS NOT NULL").
            where("#{Issue.table_name}.done_ratio > 0").
            where("#{AgileData.table_name}.story_points IS NOT NULL").
            joins(:agile_data).
            group("#{Issue.table_name}.created_on").
            sum("(#{AgileData.table_name}.story_points * (#{Issue.table_name}.done_ratio) / 100)")
      end

    end
  end
end

