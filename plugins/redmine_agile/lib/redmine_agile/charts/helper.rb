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
    class Helper
      BURNDOWN_CHART                 = 'burndown_chart'.freeze
      ISSUES_BURNDOWN_CHART          = 'issues_burndown'.freeze
      WORK_BURNDOWN_SP_CHART         = 'work_burndown_sp'.freeze
      WORK_BURNDOWN_HOURS_CHART      = 'work_burndown_hours'.freeze
      BURNUP_CHART                   = 'burnup_chart'.freeze
      ISSUES_BURNUP_CHART            = 'burnup'.freeze
      WORK_BURNUP_SP_CHART           = 'work_burnup_sp'.freeze
      WORK_BURNUP_HOURS_CHART        = 'work_burnup_hours'.freeze

      CUMULATIVE_FLOW_CHART          = 'cumulative_flow'.freeze

      VELOCITY_CHART                 = 'velocity_chart'.freeze
      ISSUES_VELOCITY_CHART          = 'issues_velocity'.freeze
      WORK_VELOCITY_SP_CHART         = 'work_velocity_sp'.freeze
      WORK_VELOCITY_HOURS_CHART      = 'work_velocity_hours'.freeze

      CYCLE_TIME_CHART               = 'cycle_time'.freeze
      LEAD_TIME_CHART                = 'lead_time'.freeze
      AVERAGE_LEAD_TIME_CHART        = 'average_lead_time'.freeze

      TRACKERS_CUMULATIVE_FLOW_CHART = 'trackers_cumulative_flow'.freeze

      AGILE_CHARTS = {
        BURNDOWN_CHART =>                 { name: :label_agile_chart_burndown, class: BurndownChart,
                                            aliases: [ISSUES_BURNDOWN_CHART, WORK_BURNDOWN_HOURS_CHART, WORK_BURNDOWN_SP_CHART] },
        BURNUP_CHART =>                   { name: :label_agile_chart_burnup, class: BurnupChart,
                                            aliases: [ISSUES_BURNUP_CHART, WORK_BURNUP_HOURS_CHART, WORK_BURNUP_SP_CHART] },
        CUMULATIVE_FLOW_CHART =>          { name: :label_agile_charts_cumulative_flow, class: CumulativeFlowChart },
        VELOCITY_CHART =>                 { name: :label_agile_charts_issues_velocity, class: VelocityChart,
                                            aliases: [ISSUES_VELOCITY_CHART, WORK_VELOCITY_HOURS_CHART, WORK_VELOCITY_SP_CHART] },
        CYCLE_TIME_CHART =>               { name: :label_agile_charts_cycle_time, class: CycleTimeChart, aliases: [LEAD_TIME_CHART, AVERAGE_LEAD_TIME_CHART] },
        TRACKERS_CUMULATIVE_FLOW_CHART => { name: :label_agile_charts_trackers_cumulative_flow, class: TrackersCumulativeFlowChart }
      }.freeze

      CHARTS_WITH_UNITS = [
        BURNDOWN_CHART,
        BURNUP_CHART,
        VELOCITY_CHART
      ].freeze

      UNIT_ISSUES = 'issues'.freeze
      UNIT_STORY_POINTS = 'story_points'.freeze
      UNIT_HOURS = 'hours'.freeze

      CHART_UNITS = {
        UNIT_ISSUES => :label_issue_plural,
        UNIT_STORY_POINTS => :label_agile_story_points,
        UNIT_HOURS => :label_agile_hours
      }.freeze

      CHART_UNIT_BY_ALIAS = {
        ISSUES_BURNDOWN_CHART => UNIT_ISSUES,
        WORK_BURNDOWN_HOURS_CHART => UNIT_HOURS,
        WORK_BURNDOWN_SP_CHART => UNIT_STORY_POINTS,
        ISSUES_BURNUP_CHART => UNIT_ISSUES,
        WORK_BURNUP_HOURS_CHART => UNIT_HOURS,
        WORK_BURNUP_SP_CHART => UNIT_STORY_POINTS,

        ISSUES_VELOCITY_CHART => UNIT_ISSUES,
        WORK_VELOCITY_HOURS_CHART => UNIT_HOURS,
        WORK_VELOCITY_SP_CHART => UNIT_STORY_POINTS,
      }

      def self.valid_chart?(name) !!AGILE_CHARTS[name] end

      def self.chart_by_alias(alias_name)
        chart_name = nil
        AGILE_CHARTS.each do |chart, value|
          if value[:aliases] && value[:aliases].include?(alias_name)
            chart_name = chart
            break
          end
        end
        chart_name
      end

      def self.valid_chart_name_by(old_chart_name)
        if valid_chart?(old_chart_name)
          old_chart_name
        elsif (chart_by_alias = chart_by_alias(old_chart_name))
          chart_by_alias
        else
          BURNDOWN_CHART
        end
      end

      def self.valid_chart_unit?(name) !!CHART_UNITS[name] end

      def self.chart_with_units?(old_chart_name)
        CHARTS_WITH_UNITS.include? valid_chart_name_by(old_chart_name)
      end

      def self.valid_chart_unit_by(old_chart_name, chart_unit)
        if chart_with_units?(old_chart_name)
          if chart_by_alias(old_chart_name)
            CHART_UNIT_BY_ALIAS[old_chart_name]
          elsif valid_chart_unit?(chart_unit)
            chart_unit
          else
            UNIT_ISSUES
          end
        end
      end

      def self.chart_unit_label_by(alias_name)
        chart_unit = CHART_UNIT_BY_ALIAS[alias_name]
        CHART_UNITS[chart_unit]
      end
    end
  end
end
