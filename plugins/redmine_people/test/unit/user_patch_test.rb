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

class UserPatchTest < ActiveSupport::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  def setup
    Setting.plugin_redmine_people = {}

    @params = { 'firstname' => 'newName', 'lastname' => 'lastname', 'mail' => 'mail@mail.com', 'language' => 'ru' }
    @user = User.find(4)
    User.current = @user
  end

  def test_create_by_anonumys_self_registration_off
    Setting.self_registration = '0'
    User.current = nil

    user = User.new
    user.safe_attributes = @params
    user.login = 'login'
    user.password, @user.password_confirmation = 'password', 'password'

    assert !user.save
  end

  def test_create_by_anonumys_self_registration_on
    Setting.self_registration = '1'
    User.current = nil

    user = User.new
    user.safe_attributes = @params
    user.login = 'login'
    user.password, @user.password_confirmation = 'password', 'password'

    assert user.save
  end

  def test_save_without_own_data_access
    @user.safe_attributes = @params
    @user.save!
    @user.reload
    assert_not_equal 'newName', @user.firstname
    assert_equal 'ru', @user.language
  end

  def test_save_with_own_data_access
    Setting.plugin_redmine_people['edit_own_data'] = '1'
    @user.safe_attributes = @params
    @user.save!
    @user.reload
    assert_equal 'newName', @user.firstname
  end

  def test_allowed_people_to_for_edit_subordinates
    manager = Person.find(3)
    subordinate = Person.find(4)

    # Without permission
    assert !manager.allowed_people_to?(:edit_people, subordinate)

    # Adds permission
    PeopleAcl.create(3, ['edit_subordinates'])
    assert manager.allowed_people_to?(:edit_people, subordinate)
  end
end
