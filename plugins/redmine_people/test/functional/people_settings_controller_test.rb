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

class PeopleSettingsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issue_statuses
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:departments, :people_information])

  def setup
    @request.session[:user_id] = 1
    @user = User.find(4)

    # Remove accesses operations
    Setting.plugin_redmine_people[:users_acl] = {}
  end

  def test_get_index
    compatible_request :get, :index
    assert_response :success
  end

  def test_put_update
    compatible_request :post, :update, :id => 1, :settings => { :visibility => '1' }, :tab => 'general'
    assert_equal '1', Setting.plugin_redmine_people['visibility']
    assert_redirected_to :action => 'index', :tab => 'general'
  end

  def test_post_destroy
    PeopleAcl.create(4, ['add_people'])

    compatible_request :post, :destroy, :id => 4
    assert_equal false, @user.allowed_people_to?(:add_people, @user)

    compatible_request :get, :index
    assert_select '#principals label', :count => 1, :text => /#{@user.name}/
    assert_select 'table .user.name a', :count => 0, :text => /#{@user.name}/
  end

  def test_post_create
    assert_equal false, @user.allowed_people_to?(:add_people, @user)

    @request.session[:user_id] = 1
    compatible_request :post, :create, :user_ids => ['4'], :acls => ['add_people']
    assert @user.allowed_people_to?(:add_people, @user)

    compatible_request :get, :index
    assert_select '#principals label', :count => 0, :text => /#{@user.name}/
    assert_select 'table .user.name a', :count => 1, :text => /#{@user.name}/
  end
end
