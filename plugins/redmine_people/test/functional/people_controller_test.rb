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

class PeopleControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper
  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  # Fixtures with the same names overwriting each other. For example, time_entries will be restored only from the People plugin.
  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_holidays, :people_work_experiences, :departments, :people_information,
                                           :custom_fields, :custom_values, :attachments, :time_entries])

  def setup
    @person = Person.find(4)
    @person_params = { :login => 'login',
                       :password => '12345678',
                       :password_confirmation => '12345678',
                       :firstname => 'Ivan',
                       :lastname => 'Ivanov',
                       :mail => 'ivan@ivanov.com',
                       :information_attributes => {
                         :facebook => 'Facebook',
                         :middlename => 'Ivanovich' },
                       :tag_list => 'Tag1, Tag2'
                     }
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
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
    [:index, :show, :new, :edit].each do |action|
      compatible_request :get, action, :id => @person.id
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @person.id
      assert_response 302, access_message(action)
    end

    compatible_request :delete, :destroy_avatar, :id => @person.id
    assert_response 302
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Get
    [:show, :index, :new, :edit].each do |action|
      compatible_request :get, action, :id => @person.id
      assert_response 403, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @person.id
      assert_response 403, access_message(action)
    end

    compatible_request :delete, :destroy_avatar, :id => @person.id
    assert_response 403
  end

  def test_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_select 'h1 a', 'Redmine Admin'
  end

  def test_get_index_without_departments
    @request.session[:user_id] = 1
    Department.delete_all
    compatible_request :get, :index, :set_filter => '1'
    assert_response :success
  end

  def test_get_show
    @request.session[:user_id] = 1
    compatible_request :get, :show, :id => @person.id
    assert_response :success
    assert_select 'h1', /Robert Hill/
  end

  def test_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success
  end

  def test_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => @person.id
    assert_response :success
    assert_select "input[value='Hill']"
  end

  def test_post_create
    @request.session[:user_id] = 1
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_redirected_to :action => 'show', :id => person.id
    assert_equal ['ivan@ivanov.com', 'Ivanovich'], [person.email, person.middlename]
    assert_equal ['Tag1', 'Tag2'], person.tag_list.sort
  end

  def test_put_update
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => @person.id,
                                       :person => {
                                         :firstname => 'firstname',
                                         :information_attributes => { :facebook => 'Facebook2' }
                                       }
    @person.reload
    assert_redirected_to :action => 'show', :id => @person.id
    assert_equal ['firstname', 'Facebook2'], [@person.firstname, @person.facebook]
  end

  def test_update_with_attachment
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => '8', :tab => 'files',
                                       :attachments => { '1' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain'),
                                                                  'description' => 'test file' } }

    assert_response 302
    assert_redirected_to tabs_person_path(8, :tab => 'files')

    attachment = Attachment.order('id DESC').first

    assert_equal User.find(8), attachment.container
    assert_equal 1, attachment.author_id
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description

    assert File.exists?(attachment.diskfile)
  end

  def test_destroy
    @request.session[:user_id] = 1
    compatible_request :post, :destroy, :id => 4
    assert_redirected_to :action => 'index'
    assert_raises(ActiveRecord::RecordNotFound) do
      Person.find(4)
    end
  end

  def test_destroy_avatar
    @request.session[:user_id] = 1
    avatar = people_uploaded_file('testfile_1.png', 'image/png')

    a = Attachment.new(:container => @person,
                       :file =>  avatar, :description => 'avatar',
                       :author => User.find(1))
    assert a.save
    assert @person.avatar.present?

    compatible_request :delete, :destroy_avatar, :id => 4
    assert_redirected_to :action => 'edit', :id => 4
    assert @person.reload.avatar.blank?
  end

  def test_load_tab
    @request.session[:user_id] = @person.id
    compatible_xhr_request :get, :load_tab, :tab_name => 'activity', :partial => 'activity', :id => @person.id
    assert_response :success

    compatible_xhr_request :get, :load_tab, :tab_name => 'files', :partial => 'attachments', :id => @person.id
    assert_response :success

    compatible_xhr_request :get, :load_tab, :tab_name => 'projects', :partial => 'projects', :id => @person.id
    assert_response :success
  end

  def test_get_new_without_default_group
    with_people_settings 'default_group' => '' do
      @request.session[:user_id] = 1
      compatible_request :get, :new
      assert_response :success
      assert_select "input[type=hidden][name='person[group_ids][]']", false, 'No groups'
    end
  end

  def test_get_new_with_default_group
    with_people_settings 'default_group' => '456' do
      @request.session[:user_id] = 1
      compatible_request :get, :new
      assert_response :success
      assert_select "input[type=hidden][name='person[group_ids][]'][value='456']"
    end
  end

  def test_post_create_with_default_group
    @request.session[:user_id] = 1
    @person_params[:group_ids] = [10]
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_equal 10, person.groups.first.id
  end

  def test_post_create_with_deleted_default_group
    @request.session[:user_id] = 1
    @person_params[:group_ids] = [777]
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_nil person.groups.first
  end

  def test_sidebar_next_holidays
    PeopleHoliday.destroy_all
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_select '#next_holidays', :count => 0

    holiday = PeopleHoliday.new(:start_date => Date.today + 5.day, :name => 'New holiday')
    holiday.save
    compatible_request :get, :index
    assert_response :success
    assert_select '#next_holidays', :count => 1
  end

  def test_get_index_with_search
    @request.session[:user_id] = 1
    with_settings :user_format => 'lastnamefirstname' do
      compatible_request :get, :index, set_filter: '1', f: [''], search: 'smithjoh'
      assert_response :success
      assert_select 'table.people td.name h1 a', 1
    end
  end

  private

  def tab_should_be_available(user_id, person_id, tab_name)
    @request.session[:user_id] = user_id

    compatible_request :get, :show, id: person_id
    assert_response :success
    assert_select "#tab-#{tab_name}", 1
    assert_select "#tab-placeholder-#{tab_name}", 1

    compatible_request :get, :show, id: person_id, tab: tab_name
    assert_response :success
    assert_select "#tab-#{tab_name}", 1
    assert_select "#tab-placeholder-#{tab_name}", 1

    compatible_xhr_request :get, :load_tab, id: person_id, tab_name: tab_name, partial: tab_name
    assert_response :success
  end

  def tab_should_not_be_available(user_id, person_id, tab_name)
    @request.session[:user_id] = user_id

    compatible_request :get, :show, id: person_id
    assert_response :success
    assert_select "#tab-#{tab_name}", 0
    assert_select "#tab-placeholder-#{tab_name}", 0

    compatible_request :get, :show, id: person_id, tab: tab_name
    assert_response :forbidden

    compatible_xhr_request :get, :load_tab, id: person_id, tab_name: tab_name, partial: tab_name
    assert_response :forbidden
  end
end
