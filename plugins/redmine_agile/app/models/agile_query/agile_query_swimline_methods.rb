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

module AgileQuery::AgileQuerySwimlineMethods
  def swimlanes
    return [] unless grouped?

    groupable_method = Redmine::VERSION.to_s > '4.2' ? :group_by_statement : :groupable
    lane_ids = issue_scope.group(group_by_column.public_send(groupable_method)).count.keys
    lanes = Issue.reflect_on_association(group_by_column.name).klass.where(id: lane_ids).reorder(group_by_sort_order)
    lanes = lanes.eager_load(:agile_data) if group_by_column.name == :parent
    lanes = lanes.to_a
    lanes << nil if lane_ids.include?(nil)
    lanes
  end

  def issue_count_by_swimlane
    @issue_count_by_swimlane ||= issue_scope.group("#{Issue.table_name}.#{group_by_column.name}_id").count if grouped?
  end
end
