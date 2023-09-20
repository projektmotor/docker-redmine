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

module AgileQuery::AgileQueryTotalMethods
  def available_totalable_columns
    return @available_totalable_columns if @available_totalable_columns

    base_total_columns = [:story_points, :hours, :spent_time]
    base_total_columns += [:percent_done, :velocity] if sprints_enabled.to_i > 0
    @available_totalable_columns = base_total_columns.map do |total|
      QueryColumn.new(total, caption: l("label_agile_board_totals_#{total}"))
    end
  end

  def total_by_swimlane(swimlane, column)
    sw_scope = issue_scope.where("#{Issue.table_name}.#{group_by_column.name}_id = ?", swimlane.try(:id))
    total_for(column, sw_scope)
  end

  def total_for(column, scope = issues)
    total_values = { story_points: scope.sum(:story_points).to_f,
                     hours: scope.sum(:estimated_hours).to_f }
    if [:percent_done, :velocity].include?(column.name)
      open_issues = scope.open
      closed_issues = scope.open(false)
      open_spent_sp = open_issues.sum("#{AgileData.table_name}.story_points / 100 * #{Issue.table_name}.done_ratio * 1.0").to_f
      closed_spent_sp = closed_issues.sum("#{AgileData.table_name}.story_points * 1.0").to_f
      open_spent_hr = open_issues.sum("#{Issue.table_name}.estimated_hours / 100 * #{Issue.table_name}.done_ratio * 1.0").to_f
      closed_spent_hr = closed_issues.sum("#{Issue.table_name}.estimated_hours * 1.0").to_f
    end

    case column.name
    when :story_points
      total_values[:story_points]
    when :hours
      total_values[:hours]
    when :spent_time
      scope.joins(:time_entries).sum("#{TimeEntry.table_name}.hours").to_f
    when :percent_done
      case chart_unit
      when 'issues'
        ((open_issues.sum("#{Issue.table_name}.done_ratio").to_f + (closed_issues.count * 100)) / scope.count).round(2)
      when 'story_points'
        return 0.0 if total_values[:story_points].zero?

        (open_spent_sp + closed_spent_sp) / total_values[:story_points] * 100
      when 'hours'
        return 0.0 if total_values[:hours].zero?

        (open_spent_hr + closed_spent_hr) / total_values[:hours] * 100
      end
    when :velocity
      sprint_duration = sprint ? sprint.length - sprint.remaining : 1
      sprint_duration = 1 if sprint_duration.zero?

      case chart_unit
      when 'issues'
        closed_issues.count.to_f / sprint_duration
      when 'story_points'
        (open_spent_sp + closed_spent_sp) / sprint_duration
      when 'hours'
        (open_spent_hr + closed_spent_hr) / sprint_duration
      end
    end
  end
end
