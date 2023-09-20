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

class AgileVersionsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
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
    RedmineAgile.create_issues
    RedmineAgile::TestCase.prepare
    @project_1 = Project.find(1)
    @project_2 = Project.find(2)
    @project_3 = Project.find(5)

    ['agile', 'agile_backlog'].each do |p_module|
      EnabledModule.create(project: @project_1, name: p_module)
      EnabledModule.create(project: @project_2, name: p_module)
      EnabledModule.create(project: @project_3, name: p_module)
    end

    @request.session[:user_id] = 1
  end

  def test_get_index
    compatible_request :get, :index, project_id: @project_1
    assert_response :success
    assert_match /Version planning/, @response.body
    assert_match /2.0/, @response.body
    assert_match /Private Version of public subproject/, @response.body
    assert_match /Systemwide visible version/, @response.body
  end

  def test_get_autocomplete_id
    compatible_xhr_request :get, :autocomplete, project_id: 'ecookbook', q: '#3'
    assert_response :success
    assert_match 'Error 281', @response.body
  end

  def test_get_autocomplete_text
    compatible_xhr_request :get, :autocomplete, project_id: 'ecookbook', q: 'error'
    assert_response :success
    assert_match 'Error 281', @response.body
  end

  def test_get_load_more
    compatible_xhr_request :get, :load_more, version_id: '3', project_id: 'ecookbook', page: '2'
    assert_response :success
  end

  def test_get_index_with_filter
    compatible_request :get, :index, only_open_params

    assert_response :success

    assert_match /Blaa/, @response.body
    assert_match /Issue 100/, @response.body

    assert_no_match /(Issue 105)|(Issue 106)|(Issue 109)/, @response.body
  end

  def test_get_index_with_version_filter
    compatible_request :get, :index, version_params

    assert_no_match /Issue 104/, @response.body
    assert_match /(Issue 108)|(Issue 109)/, @response.body
  end

  private

  def only_open_params
    { f: ['status_id'], op: { 'status_id' => 'o' }, project_id: @project_2 }
  end

  def version_params
    { f: ['fixed_version_id'], op: { 'fixed_version_id' => '=' }, v: { 'fixed_version_id' => ['7'] }, project_id: @project_2 }
  end
end
