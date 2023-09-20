# encoding: utf-8
#
# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../../test_helper', __FILE__)

class Redmine::ApiTest::ChecklistsTest < Redmine::ApiTest::Base
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

  RedmineChecklists::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_checklists).directory + '/test/fixtures/', [:checklists])

  def setup
    Setting.rest_api_enabled = '1'
  end

  def test_get_checklists_xml
    compatible_api_request :get, '/issues/1/checklists.xml', {}, credentials('admin')

    assert_select 'checklists[type=array]' do
      assert_select 'checklist' do
        assert_select 'id', :text => '1'
        assert_select 'subject', :text => 'First todo'
      end
    end
  end

  def test_get_checklists_with_section_xml
    compatible_api_request :get, '/issues/2/checklists.xml', {}, credentials('admin')

    assert_select 'checklists[type=array]' do
      assert_select 'checklist' do
        assert_select 'id', :text => '4'
        assert_select 'subject', :text => 'New section'
        assert_select 'is_section', :text => 'true'
      end
    end
  end

  def test_get_checklists_1_xml
    compatible_api_request :get, '/checklists/1.xml', {}, credentials('admin')

    assert_select 'checklist' do
      assert_select 'id', :text => '1'
      assert_select 'subject', :text => 'First todo'
    end
  end

  def test_get_checklists_2_with_section_xml
    compatible_api_request :get, '/checklists/4.xml', {}, credentials('admin')

    assert_select 'checklist' do
      assert_select 'id', :text => '4'
      assert_select 'subject', :text => 'New section'
      assert_select 'is_section', :text => 'true'
    end
  end

  def test_checklists_2_should_not_section_xml
    compatible_api_request :get, '/checklists/3.xml', {}, credentials('admin')

    assert_select 'checklist' do
      assert_select 'id', :text => '3'
      assert_select 'subject', :text => 'Third todo'
      assert_select 'is_section', :text => 'false'
    end
  end

  def test_post_checklists_xml
    parameters = { :checklist => { :issue_id => 1,
                                   :subject => 'api_test_001',
                                   :is_done => true } }
    assert_difference('Checklist.count') do
      compatible_api_request :post, '/issues/1/checklists.xml', parameters, credentials('admin')
    end

    checklist = Checklist.order('id DESC').first
    assert_equal parameters[:checklist][:subject], checklist.subject

    assert_response :created
    assert_match 'application/xml', @response.content_type
    assert_select 'checklist id', :text => checklist.id.to_s
  end

  def test_put_checklists_1_xml
    parameters = { :checklist => { subject: 'Item_UPDATED', is_done: '1' } }

    assert_no_difference('Checklist.count') do
      compatible_api_request :put, '/checklists/1.xml', parameters, credentials('admin')
    end

    checklist = Checklist.find(1)
    assert_equal parameters[:checklist][:subject], checklist.subject
  end

  def test_recalculate_ratio_after_multirequests
    issue = Issue.find(1)
    with_checklists_settings('issue_done_ratio' => '1') do
      assert_equal 0, issue.reload.done_ratio

      parameters_array = [
        [1, { :checklist => { subject: 'Item 1', is_done: '1' } }],
        [2, { :checklist => { subject: 'Item 2', is_done: '1' } }],
        [1, { :checklist => { subject: 'Item 1', is_done: '0' } }],
        [2, { :checklist => { subject: 'Item 2', is_done: '1' } }]
      ]

      assert_no_difference('Checklist.count') do
        parameters_array.each do |params|
          compatible_api_request :put, "/checklists/#{params[0]}.xml", params[1], credentials('admin')
          assert ['200', '204'].include?(response.code)
        end
      end

      assert_equal 50, issue.reload.done_ratio
    end
  end

  def test_delete_1_xml
    assert_difference 'Checklist.count', -1 do
      compatible_api_request :delete, '/checklists/1.xml', {}, credentials('admin')
    end

    assert ['200', '204'].include?(response.code)
    assert_equal '', @response.body
    assert_nil Checklist.find_by_id(1)
  end
end
