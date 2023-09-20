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

class AgileVersionsQueryTest < ActiveSupport::TestCase
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

  def filter_fields
    ['assigned_to_id', 'tracker_id', 'status_id', 'author_id', 'category_id'] # estimated_hours
  end

  def setup
    super
    RedmineAgile.create_issues
    @query = AgileVersionsQuery.new(:name => '_')
    @query.project = Project.find(2)
    @version5 = Version.find(5)
    @version7 = Version.find(7)
    User.current = User.find(1) # because issues selected according permissions
  end

  def test_versions
    assert_equal [5, 7], @query.versions.map(&:id).sort
  end

  def test_no_version_issues
    assert_equal [4, 107], @query.no_version_issues.map(&:id).sort
  end

  def test_version_issues
    assert_equal [104], @query.version_issues(@version5).map(&:id).sort
  end

  def test_query_version_filter
    hash = { f: ['fixed_version_id'], op: { 'fixed_version_id' => '=' }, v: { 'fixed_version_id' => ['7'] } }
    @query.build_from_params(hash)
    assert_equal [4, 107, 108, 109], @query.no_version_issues.map(&:id).sort
    assert_equal [], @query.version_issues(@version5).map(&:id).sort
    assert_equal [100, 101, 102, 103], @query.version_issues(@version7).map(&:id).sort
  end

  def test_query_version_filter_if_current_and_other_versions_are_selected
    hash = { f: ['fixed_version_id'], op: { 'fixed_version_id' => '=' }, v: { 'fixed_version_id' => ['current_version', '7'] } }
    @query.build_from_params(hash)
    assert_equal [4, 107, 108, 109], @query.no_version_issues.map(&:id).sort
    assert_equal [104, 105, 106], @query.version_issues(@version5).map(&:id).sort
    assert_equal [100, 101, 102, 103], @query.version_issues(@version7).map(&:id).sort
  end
end
