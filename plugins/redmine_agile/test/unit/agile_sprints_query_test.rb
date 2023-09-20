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

require File.expand_path('../../test_helper', __FILE__)

class AgileSprintsQueryTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issue_statuses,
           :issues,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  def setup
    super
    RedmineAgile.create_issues
    @query = AgileSprintsQuery.new(:name => '_')
    @query.project = Project.find(1)
    @sprint = AgileSprint.find(1)
    User.current = User.find(1) # because issues selected according permissions
  end

  def test_should_return_sprint_total_time_story_points
    default_values = {}
    default_values[:version_board], default_values[:story_points_on] = @version_board, Setting.plugin_redmine_agile['story_points_on']

    @version_board = false
    Setting.plugin_redmine_agile['story_points_on'] = '1'
    @query.column_names = [:story_points]
    result = @query.sprint_total_time_story_points(@query, @sprint).to_f
    @version_board, Setting.plugin_redmine_agile['story_points_on'] = default_values[:version_board], default_values[:story_points_on]

    assert_equal(2.0, result)
  end

  def test_should_not_return_sprint_total_time_story_points
    default_values = {}
    default_values[:version_board], default_values[:story_points_on] = @version_board, Setting.plugin_redmine_agile['story_points_on']

    @version_board = false
    Setting.plugin_redmine_agile['story_points_on'] = '1'
    @query.column_names = [:story_points]
    @sprint = AgileSprint.find(2)

    result = @query.sprint_total_time_story_points(@query, @sprint).to_f
    @version_board, Setting.plugin_redmine_agile['story_points_on'] = default_values[:version_board], default_values[:story_points_on]

    assert_equal(0.0, result)
  end

end
