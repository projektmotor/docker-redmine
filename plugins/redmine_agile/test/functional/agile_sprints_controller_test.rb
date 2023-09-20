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

class AgileSprintsControllerTest < ActionController::TestCase
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

  RedmineAgile::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_agile).directory + '/test/fixtures/', [:agile_data, :agile_sprints])

  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @sprint = AgileSprint.find(1)

    ['agile', 'agile_backlog'].each do |p_module|
      EnabledModule.create(project: @project, name: p_module)
    end
  end

  def test_get_new
    compatible_request :get, :new, project_id: @project.identifier
    assert_response :success
    assert_select 'input#agile_sprint_name', 1
  end

  def test_post_create
    assert_difference 'AgileSprint.count' do
      compatible_request :post, :create, project_id: @project.identifier, agile_sprint: { name: 'Sprint #1',
                                                                                          status: AgileSprint::OPEN,
                                                                                          start_date: Date.today + 1.year,
                                                                                          end_date: Date.today + 1.year + 14.days }
      assert_response :redirect
    end
  end

  def test_post_create_for_existed_sprints
    assert_no_difference 'AgileSprint.count' do
      compatible_request :post, :create, project_id: @project.identifier, agile_sprint: { name: 'Overlapping sprint',
                                                                                          status: AgileSprint::OPEN,
                                                                                          start_date: Date.today + 2.days,
                                                                                          end_date: Date.today + 3.days }
      assert_response :success
      assert_select 'li', 'Sprint dates are cross another existed sprint'
    end
  end

  def test_post_create_for_existed_sprints_with_allowed_overlapping
    with_agile_settings('ovelapping_sprints' => 1) do
      assert_difference 'AgileSprint.count' do
        compatible_request :post, :create, project_id: @project.identifier, agile_sprint: { name: 'Overlapping sprint',
                                                                                            status: AgileSprint::OPEN,
                                                                                            start_date: Date.today + 2.days,
                                                                                            end_date: Date.today + 3.days }
        assert_response :redirect
      end
    end
  end

  def test_get_edit
    compatible_request :get, :edit, id: @sprint.id, project_id: @project.identifier
    assert_response :success
    assert_select 'input#agile_sprint_name[value=?]', @sprint.name
  end

  def test_put_update
    compatible_request :put, :update, id: @sprint.id, project_id: @project.identifier, agile_sprint: { name: 'New sprint name' }
    assert_response :redirect
  end

  def test_close_with_open_issues
    assert_equal true, @sprint.issues.open.any?
    compatible_request :put, :update, id: @sprint.id, project_id: @project.identifier, agile_sprint: { status: AgileSprint::CLOSED }
    assert_response :success
    assert_select 'li', "The sprint with open issues cannot be closed"
  end

  def test_get_story_points
    params = {
        sprint_ids: [1, 2],
        project_id: @project.id
    }
    compatible_xhr_request :get, :get_story_points, params
    assert_response :success
    assert_equal("{\"1\":2}", response.body)
  end

  def test_get_story_points
    params = {
        sprint_ids: [1, 2],
        project_id: @project.id
    }
    compatible_xhr_request :get, :get_story_points, params
    assert_response :success
    assert_equal("{\"1\":2,\"2\":0}", response.body)
  end
end
