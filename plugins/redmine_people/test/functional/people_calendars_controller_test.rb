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

class PeopleCalendarsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_holidays, :departments, :people_information, :custom_fields, :custom_values, :attachments])

  def setup
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
    set_fixtures_attachments_directory
  end

  def test_without_authorization
    compatible_request :get, :index
    assert_response 302
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    compatible_request :get, :index
    assert_response 403
  end

  def test_with_access_rights
    PeopleAcl.create(2, ['view_people'])
    @request.session[:user_id] = 2
    compatible_request :get, :index
    assert_response :success
  end

  def test_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_select 'h2', 'Calendar'
  end

  def test_get_index_with_holiday
    @request.session[:user_id] = 1
    compatible_request :get, :index, :month => 1, :year => 2017, :set_filter => 1
    assert_response :success
    assert_match /Holiday 2/, @response.body
  end

  def test_get_index_with_holidays
    @request.session[:user_id] = 1
    compatible_request :get, :index, :month => 4, :year => 2017, :set_filter => 1
    assert_response :success
    assert_select '.holiday .ending' do |elements|
      assert_equal 2, elements.count
    end
  end

  def test_get_index_with_birthday
    @request.session[:user_id] = 1
    compatible_request :get, :index, :month => 7, :year => 2017, :set_filter => 1
    assert_response :success
    assert_select '.birthday a', :count => 2, :text => 'Redmine Admin'
  end

  def test_get_index_without_birthday
    @request.session[:user_id] = 1
    compatible_request :get, :index, :month => 7, :year => 2017, :set_filter => 1, :set_birthdays => 1
    assert_response :success
    assert_select '.birthday a', :count => 0, :text => 'Redmine Admin'
  end
end
