# encoding: utf-8
#
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

module AgileSprintsHelper
  def sprint_values_for_select_for(project)
    project_sprints = project.shared_agile_sprints.available
    return [] unless project_sprints.any?

    future_sprints = project_sprints.where(status: AgileSprint::OPEN).where('start_date >= ? ', Date.today)
    active_sprints = project_sprints.where(status: AgileSprint::ACTIVE)
    old_sprints = project_sprints.where(status: AgileSprint::OPEN).where('start_date <= ? ', Date.today)

    grouped_sprints = []
    grouped_sprints << [l('label_agile_sprint_list_future'), future_sprints.map { |s| [s.to_s, s.id.to_s] }] if future_sprints.any?
    grouped_sprints << [l('label_agile_sprint_list_active'), active_sprints.map { |s| [s.to_s, s.id.to_s] }] if active_sprints.any?
    grouped_sprints << [l('label_agile_sprint_list_old'), old_sprints.map { |s| [s.to_s, s.id.to_s] }] if old_sprints.any?
    grouped_sprints
  end

  def sprint_status_values_for_select
    AgileSprint.statuses.map { |status, value| [l("label_agile_sprint_status_#{status}"), value] }
  end

  def sprint_sharing_values_for_select
    AgileSprint.sharings.map { |share, value| [l("label_agile_sprint_sharing_#{share}"), value] }
  end

  def duration_values_for_select
    [[l(:label_agile_sprint_duration_select), nil]] + (1..4).map { |week| [l("label_agile_sprint_duration_week_#{week}"), week] }
  end
end
