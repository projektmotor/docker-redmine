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

class IssuesControllerTest < ActionController::TestCase
  include Redmine::I18n

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
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'agile')
    EnabledModule.create(:project => @project_2, :name => 'agile')
    @request.session[:user_id] = 1
  end
  def test_get_index_with_colors
    with_agile_settings "color_on" => "issue" do
      issue = Issue.find(1)
      issue.color = AgileColor::AGILE_COLORS[:red]
      issue.save
      compatible_request :get, :index
      assert_response :success
      assert_select 'tr#issue-1.issue.bk-red', 1
    end
  end

  def test_get_index_with_sprint_filter
    issue = Issue.find(1)
    sprint = AgileSprint.find(1)
    issue.agile_sprint = sprint
    issue.save
    compatible_request :get,
      :index,
      # :params => {
        # :set_filter => 1,
        "set_filter"=>"1", "sort"=>"id:desc", "f"=>["agile_sprints", ""], "op"=>{"agile_sprints"=>"="}, "v"=>{"agile_sprints"=>["1"]}, "c"=>["agile_sprint"]
        # :c => ['agile_sprints'],
        # :f => ['agile_sprints'],
        # :op => {'agile_sprints' => '='},
        # :v => {'agile_sprints' => ['1']
        # }

    compatible_request :get, :index
    assert_response :success
    # assert_equal @response.body.to_s, 'ds'
    assert_select 'tr#issue-1 td.agile_sprint', sprint.to_s

    # QueriesControllerTest {"project_id"=>"1", "type"=>"IssueQuery", "name"=>"agile_sprints"}
  end

  def test_post_issue_journal_color
    with_agile_settings 'color_on' => 'issue' do
      compatible_request :put, :update, :id => 1, :issue => { :agile_color_attributes => { :color => AgileColor::AGILE_COLORS[:red] } }
      issue = Issue.find(1)
      details = issue.journals.order(:id).last.details.last
      assert issue.color
      assert_equal 'color', details.prop_key
      assert_equal AgileColor::AGILE_COLORS[:red], details.value
    end
  end

  def test_index_with_story_points_total
    compatible_request :get, :index, t: ['story_points']
    assert_response :success
    assert_select '.query-totals .total-for-story-points', text: l(:field_story_points) + ': 3'
  end if Redmine::VERSION.to_s >= '3.4'

  def test_index_with_story_points_total_and_grouping
    compatible_request :get, :index, t: ['story_points'], group_by: 'project'
    assert_response :success
    assert_select '.query-totals .total-for-story-points', text: l(:field_story_points) + ': 3'
    assert_select 'tr.group', count: 4 do
      assert_select '.total-for-story-points .value', text: '3', count: 1
      assert_select '.total-for-story-points', text: 'Story points: 3', count: 1
      assert_select '.total-for-story-points', text: 'Story points: 0', count: 3
    end
  end if Redmine::VERSION.to_s >= '3.4'

  def test_new_issue_with_sp_value
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      compatible_request :get, :new, :project_id => 1
      assert_response :success
      assert_select 'input#issue_agile_data_attributes_story_points'
    end
  end

  def test_new_issue_without_sp_value
    with_agile_settings 'estimate_units' => 'hours', 'story_points_on' => '0' do
      compatible_request :get, :new, :project_id => 1
      assert_response :success
      assert_select 'input#issue_agile_data_attributes_story_points', :count => 0
    end
  end

  def test_create_issue_with_sp_value
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      assert_difference 'Issue.count' do
        compatible_request :post, :create, :project_id => 1, :issue => {
          :subject => 'issue with sp',
          :tracker_id => 3,
          :status_id => 1,
          :priority_id => IssuePriority.first.id,
          :agile_data_attributes => { :story_points => 50 }
        }
      end
      issue = Issue.last
      assert_equal 'issue with sp', issue.subject
      assert_equal 50, issue.story_points
    end
  end

  def test_post_issue_journal_story_points
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      compatible_request :put, :update, :id => 1, :issue => { :agile_data_attributes => { :story_points => 100 } }
      issue = Issue.find(1)
      assert_equal 100, issue.story_points
      sp_history = JournalDetail.where(:property => 'attr', :prop_key => 'story_points', :journal_id => issue.journals).last
      assert sp_history
      assert_equal 100, sp_history.value.to_i
    end
  end

  def test_show_issue_with_story_points
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      compatible_request :get, :show, :id => 1
      assert_response :success
      assert_select '#issue-form .attributes', :text => /Story points/, :count => 1
    end
  end

  def test_show_issue_with_order_by_story_points
    session[:issue_query] = { :project_id => Issue.find(1).project_id,
                              :filters => { 'status_id' => { :operator => 'o', :values => [''] } },
                              :group_by => '',
                              :column_names => [:tracker, :status, :story_points],
                              :totalable_names => [],
                              :sort => [['story_points', 'asc'], ['id', 'desc']]
                            }
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      compatible_request :get, :show, :id => 1
      assert_response :success
      assert_select '#issue-form .attributes', :text => /Story points/, :count => 1
    end
  ensure
    session[:issue_query] = {}
  end
  def test_update_issue_story_points_save_sprint
    @request.session[:user_id] = 2
    with_agile_settings 'estimate_units' => 'story_points', 'story_points_on' => '1' do
      issue = Issue.find(2)
      assert issue.agile_sprint
      compatible_request :put, :update, id: 2, issue: { agile_data_attributes: { agile_sprint_id: 0, story_points: 3 } }
      assert_response :redirect
      assert issue.reload.agile_sprint
    end
  end

  def test_show_issue_form_with_story_points_select
    with_agile_settings('sp_values' => [1,2,3],
      'estimate_units' => 'story_points', 'story_points_on' => '1') do
        compatible_request :get, :new, :project_id => 1
        assert_response :success
        assert_select 'select#issue_agile_data_attributes_story_points'
    end
  end

  def test_dont_show_story_points_select_when_no_sp_values
    with_agile_settings('sp_values' => [],
      'estimate_units' => 'story_points', 'story_points_on' => '1') do
        compatible_request :get, :new, :project_id => 1
        assert_response :success
        assert_select 'select#issue_agile_data_attributes_story_points', :count => 0
    end
  end

  def test_bulk_update_for_sprint_with_story_points
    issues = Issue.where(id: [1,2])
    assert_equal [1, 2], issues.map { |issue| issue.agile_data.story_points }
    with_agile_settings('sp_values' => [1,2,3], 'estimate_units' => 'story_points', 'story_points_on' => '1') do
        compatible_request :post, :bulk_update, ids: [1,3], issue: { agile_data_attributes: { agile_sprint_id: '1', id: '' } }
        assert_response :redirect
        assert_equal [1, 2], issues.map { |issue| issue.agile_data.story_points }
    end
  end

  def test_bulk_update_save_agile_data_for_copies
    issue_ids = [1, 3]
    issues = Issue.where(id: issue_ids)
    assert_equal [1, 0], issues.map { |issue| issue.agile_data.story_points.to_i }
    with_agile_settings('sp_values' => [1,2,3], 'estimate_units' => 'story_points', 'story_points_on' => '1') do
        compatible_request :post, :bulk_update, { ids: issue_ids, link_copy: 1, copy: 1, copy_subtasks: 1 }
        assert_response :redirect
        assert_equal [1, 0], Issue.last(2).map { |issue| issue.agile_data.story_points.to_i }
    end
  end

  def test_issue_bulk_edit_with_sprint_field
    compatible_request :get, :bulk_edit, ids: [1, 2]
    assert_response :success
    assert_match "issue_agile_data_attributes_agile_sprint_id", @response.body
  end

  def test_issue_bulk_update_with_sprint_field
    issues = Issue.where(id: [1, 2])
    compatible_request :post, :bulk_update, ids: [1, 2], issue: { agile_data_attributes: { agile_sprint_id: '1' } }
    assert_response :redirect
    assert_equal [1, 1], issues.map { |issue| issue.agile_sprint.id }
  end

  def test_issue_bulk_edit_with_color_field
    with_agile_settings('color_on' => 'issue') do
      compatible_request :get, :bulk_edit, ids: [1, 2]
      assert_response :success
      assert_select "#issue_agile_color_attributes_color"
    end
  end

  def test_issue_bulk_update_with_color_field
    issues = Issue.where(id: [1, 2])
    params = {
        ids: [1, 2],
        issue: {
            agile_color_attributes: {
                color: AgileColor::AGILE_COLORS[:green]
            }
        }
    }
    with_agile_settings('color_on' => 'issue') do
      compatible_request :post, :bulk_update, params
      assert_response :redirect
      assert_equal ['green', 'green'], issues.map { |issue| issue.color }
    end
  end

  def test_issue_bulk_update_with_clean_color_value
    params = {
        ids: [1, 2],
        issue: {
            agile_color_attributes: {
                color: 'none'
            }
        }
    }

    with_agile_settings('color_on' => 'issue') do
      issues = Issue.where(id: [1, 2])
      issues.each do |issue|
        issue.color = AgileColor::AGILE_COLORS[:green]
        issue.save
      end

      compatible_request :post, :bulk_update, params
      assert_response :redirect
      updated_issues = Issue.where(id: [1, 2])
      updated_issues.each do |issue|
        assert_equal('none', issue.color)
      end
    end
  end

  def test_issue_bulk_edit_without_color_field
    compatible_request :get, :bulk_edit, ids: [1, 2]
    assert_response :success
    assert_select "#issue_agile_color_attributes_color", false
  end

  def test_issue_bulk_edit_with_sp_field
    with_agile_settings('story_points_on' => '1') do
      compatible_request :post, :bulk_edit, {ids: [1, 2], issue: { tracker_id: '3' }}
      assert_response :success
      assert_select "#issue_agile_data_attributes_story_points"
    end
  end

  def test_issue_bulk_update_with_sp_field
    issues = Issue.where(id: [1, 2])
    params = {
        ids: [1, 2],
        issue: {
            agile_data_attributes: {
                story_points: '3'
            },
            tracker_id: '3'
        }
    }
    with_agile_settings('story_points_on' => '1') do
      compatible_request :post, :bulk_update, params
      assert_response :redirect
      assert_equal [3, 3], issues.map { |issue| issue.story_points }
    end
  end

  def test_issue_bulk_edit_without_sp_field
    with_agile_settings('story_points_on' => '0') do
      compatible_request :post, :bulk_edit, {ids: [1, 2], issue: { tracker_id: '2' }}
      assert_response :success
      assert_select "#issue_agile_data_attributes_story_points", false
    end
  end

  def test_update_for_sprint_with_story_points
    @request.session[:user_id] = 2 # User without manage_sprints permission
    issue = Issue.find(2)
    assert_equal 1, issue.agile_data.agile_sprint_id
    assert_equal 2, issue.agile_data.story_points
    with_agile_settings('sp_values' => [1,2,3], 'estimate_units' => 'story_points', 'story_points_on' => '1') do
      compatible_request :put, :update, id: issue.id, issue: { agile_data_attributes: { story_points: '3', id: issue.agile_data.id } }
      assert_response :redirect
      issue.reload
      assert_equal 1, issue.agile_data.agile_sprint_id
      assert_equal 3, issue.agile_data.story_points
    end
  end
end
