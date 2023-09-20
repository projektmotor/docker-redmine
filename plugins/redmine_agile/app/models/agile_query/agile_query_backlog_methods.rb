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

module AgileQuery::AgileQueryBacklogMethods
  def backlog_column
    return nil if project.nil? || sprints_enabled.to_i == 0
    @backlog_column ||= options[:backlog_column]
  end

  def backlog_column=(val)
    @backlog_column = val
  end

  def backlog_column?
    backlog_column.to_i > 0
  end

  def backlog_issue_scope
    return base_agile_query_scope.where("1=1") unless backlog_column?

    base_agile_query_scope.where("#{AgileData.table_name}.agile_sprint_id" => nil)
  end

  def backlog_issues(options = {})
    @backlog_issues_cache ||= {}
    return @backlog_issues_cache[options.to_s] if @backlog_issues_cache.has_key?(options.to_s)

    backlog_issues = issues(options.merge(scope: backlog_issue_scope))
    order_by = options[:order] || "#{AgileData.table_name}.position"
    if q = (options[:q] || options[:term]).to_s.strip
      if q.match(/^#?(\d+)\z/)
        backlog_issues = backlog_issues.where("(CAST(#{Issue.table_name}.id AS char) LIKE ?) OR (LOWER(#{Issue.table_name}.subject) LIKE LOWER(?))", "#{$1}%", "%#{q}%")
      else
        backlog_issues = backlog_issues.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%")
      end
    end
    @backlog_issues_cache[options.to_s] = backlog_issues.order(order_by)
  end
end
