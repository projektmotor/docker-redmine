# encoding: utf-8
#
# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class DepartmentsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles,
           :enabled_modules, :issue_statuses, :issues, :trackers
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:departments, :people_information, :attachments])
  def setup
    Setting.plugin_redmine_people = {}

    @person = Person.find(4)
    @department = Department.find(2)
    set_fixtures_attachments_directory
  end

  def teardown
    set_tmp_attachments_directory
  end

  def access_message(action)
    "No access for the #{action} action"
  end

  def test_without_authorization
    # Get
    [:index, :show].each do |action|
      compatible_request :get, action, :id => @department.id
      assert_response :success, access_message(action)
    end

    [:new, :edit].each do |action|
      compatible_request :get, action, :id => @department.id
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @department.id
      assert_response 302, access_message(action)
    end
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @department.id
      assert_response 403, access_message(action)
    end
  end

  def test_get_index
    @request.session[:user_id] = 1

    compatible_request :get, :index
    assert_response :success
    assert_select 'a', /FBI department 1/
    assert_select 'a', /FBI department 2/
  end

  def test_get_show
    @request.session[:user_id] = 1
    compatible_request :get, :show, :id => @department.id
    assert_select 'h3', /FBI department 2/
  end

  def test_load_tab
    compatible_xhr_request :get, :load_tab, :tab_name => 'files', :partial => 'attachments', :id => 2
    assert_response :success
    assert_match /document.txt/, @response.body
  end

  def test_post_create
    @request.session[:user_id] = 1
    compatible_request :post, :create, :department => { :name => 'New Department' }
    assert_response 302
    assert_equal 'New Department', Department.last.name
  end

  def test_should_change_person_department_on_create
    @request.session[:user_id] = 1
    assert_equal @person.department_id, 3
    compatible_request :post, :create, department: { name: 'New Department', head_id: @person.id }
    assert_response :redirect
    department = Department.last
    assert_equal 'New Department', department.name
    assert_equal @person.reload.department_id, department.id
  end

  def test_should_change_person_department_on_update
    @request.session[:user_id] = 1
    assert_not_equal @person.department_id, @department.id
    compatible_request :post, :update, id: @department.id, department: { head_id: @person.id }
    assert_response :redirect
    assert_equal @person.reload.department_id, @department.id
  end

  def test_post_update_with_attachment
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => @department.id, :department => { :name => 'New Department' },
                                       :attachments => { '4' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain'),
                                                                  'description' => 'test file' } }

    assert_response 302

    assert_equal 'New Department', @department.reload.name

    attachment = Attachment.order('id DESC').first

    assert_equal @department, attachment.container
    assert_equal 1, attachment.author_id
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description
    assert File.exists?(attachment.diskfile)
  end

  def test_post_destroy
    @request.session[:user_id] = 1
    compatible_request :post, :destroy, :id => @department.id
    assert_response 302
    assert_raises(ActiveRecord::RecordNotFound) do
      Department.find(2)
    end
  end

  def test_add_people_to_department
    @request.session[:user_id] = 1
    compatible_request :post, :add_people, :id => @department.id, :person_id => @person.id
    assert_response 302
    assert_equal @department.id, @person.department_id
  end

  def test_remove_person
    @request.session[:user_id] = 1
    compatible_request :post, :remove_person, :id => @department.id, :person_id => @person.id
    assert_response 302
    assert !@department.people.include?(@person)
  end

  def test_create_with_manage_departments_access
    PeopleAcl.create(2, ['manage_departments'])
    @request.session[:user_id] = 2
    compatible_request :post, :create, :department => { :name => 'New Department' }
    assert_response 302
    assert_equal 'New Department', Department.last.name
  end

  def test_update_with_manage_departments_access
    PeopleAcl.create(2, ['manage_departments'])
    @request.session[:user_id] = 2
    compatible_request :post, :update, :id => @department.id, :department => { :name => 'New Department Name' }
    assert_response 302
    assert_equal 'New Department Name', @department.reload.name
  end

  def test_destroy_with_manage_departments_access
    PeopleAcl.create(2, ['manage_departments'])
    @request.session[:user_id] = 2
    compatible_request :post, :destroy, :id => @department.id
    assert_response 302
    assert_raises(ActiveRecord::RecordNotFound) do
      Department.find(2)
    end
  end

  def test_org_chart_for_admin
    @request.session[:user_id] = 1
    compatible_request :get, :org_chart
    assert_response :success
  end

  def test_org_chart_for_regular_user
    @request.session[:user_id] = 2
    compatible_request :get, :org_chart
    assert_response :forbidden

    PeopleAcl.create(2, ['manage_departments'])
    compatible_request :get, :org_chart
    assert_response :success
  end

  def test_org_chart_for_anonymous
    compatible_request :get, :org_chart
    assert_response :redirect
  end

  def test_org_chart_for_anonymous_without_login_required
    with_settings(login_required: '0') do
      compatible_request :get, :org_chart
      assert_response :redirect
    end
  end
end
