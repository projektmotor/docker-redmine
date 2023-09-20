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

class PersonTest < ActiveSupport::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_information, :departments, :time_entries, :people_holidays])

  def setup
    # Remove accesses operations
    User.current = nil
    Setting.plugin_redmine_people = {}

    @admin = User.find(1)
    @params = { 'firstname' => 'newName',
                'mail' => 'new@mail.ru',
                'information_attributes' => {
                  'id' => 4,
                  'phone' => '89555555555',
                  'is_system' => QUOTED_TRUE
                }
              }
    @person = Person.find(4)
  end

  def test_manager
    assert_equal 3, @person.manager.id
  end

  def test_subordinates
    assert (not Person.new.subordinates.any?)
    assert (not @person.subordinates.any?)
    assert_equal [4], Person.find(3).subordinates.map(&:id)
  end

  def test_managers
    assert_equal [3], Person.managers.map(&:id)
  end

  def test_available_managers
    if Redmine::VERSION.to_s < '3.2'
      assert_equal [1, 2, 3, 4, 5, 7, 8, 9], Person.new.available_managers.map(&:id).sort
      assert_equal [1, 2, 3, 5, 7, 8, 9], @person.available_managers.map(&:id).sort
      assert_equal [1, 2, 5, 7, 8, 9], Person.find(3).available_managers.map(&:id).sort
    else
      assert_equal [1, 2, 3, 4, 7, 8, 9], Person.new.available_managers.map(&:id).sort
      assert_equal [1, 2, 3, 7, 8, 9], @person.available_managers.map(&:id).sort
      assert_equal [1, 2, 7, 8, 9], Person.find(3).available_managers.map(&:id).sort
    end
  end

  def test_available_subordinates
    if Redmine::VERSION.to_s < '3.2'
      assert_equal [1, 2, 3, 4, 5, 7, 8, 9], Person.new.available_subordinates.map(&:id).sort
      assert_equal [1, 2, 5, 7, 8, 9], @person.available_subordinates.map(&:id).sort
      assert_equal [1, 2, 5, 7, 8, 9], Person.find(3).available_subordinates.map(&:id).sort
    else
      assert_equal [1, 2, 3, 4, 7, 8, 9], Person.new.available_subordinates.map(&:id).sort
      assert_equal [1, 2, 7, 8, 9], @person.available_subordinates.map(&:id).sort
      assert_equal [1, 2, 7, 8, 9], Person.find(3).available_subordinates.map(&:id).sort
    end
  end

  def test_remove_subordinate
    User.current = @admin

    person_3 = Person.find(3)
    person_3.remove_subordinate(4)
    assert_nil @person.reload.manager_id
  end

  def test_save_without_access
    # Editing by an anonymous user
    @person.safe_attributes = @params
    @person.save!
    @person.reload
    assert_not_equal '89555555555', @person.phone

    # User changes himself but edit_own_data is disabled
    Setting.plugin_redmine_people['edit_own_data'] = '0'

    User.current = User.find(4)
    @person.safe_attributes = @params
    @person.save!
    assert_not_equal '89555555555', @person.phone
  end

  def test_save_with_edit_own_data_access
    User.current = User.find(4)
    Setting.plugin_redmine_people['edit_own_data'] = '1'

    @person.safe_attributes = @params
    @person.save!
    assert_equal 'newName', @person.reload.firstname
    assert_equal 'new@mail.ru', @person.email
    assert_equal '89555555555', @person.phone

    # Can not change its own system fields
    assert !@person.is_system
  end

  def test_save_with_edit_people_access
    User.current = User.find(2)
    PeopleAcl.create(2, ['edit_people'])

    @person.safe_attributes = @params
    @person.save!
    assert_equal '89555555555', @person.phone
    assert_equal true, @person.is_system
  end

  def test_create_with_edit_people_access
    User.current = User.find(2)
    PeopleAcl.create(2, ['edit_people'])

    person = Person.new
    person.login = 'login'

    person.safe_attributes = { 'lastname' => 'lastname',
                               'firstname' => 'newName', 'mail' => 'new@mail.ru',
                               'information_attributes' => {
                                 'phone' => '89555555555', 'is_system' => QUOTED_TRUE
                               }
                             }
    person.type = 'User'
    person.save!
    assert_equal 'new@mail.ru', person.mail
    assert_equal '89555555555', person.phone
    assert_equal true, person.is_system
  end

  def test_save_with_edit_subordinates_access
    manager = Person.find(3)
    User.current = manager

    # Without permission
    @person.safe_attributes = @params
    @person.save!
    assert_not_equal 'newName', @person.reload.firstname

    # Adds permission
    PeopleAcl.create(3, ['edit_subordinates'])
    @person.safe_attributes = @params
    @person.save!
    assert_equal 'newName', @person.reload.firstname
  end

  def test_destroy
    Person.find(4).destroy
    assert_nil PeopleInformation.where(:user_id => 4).first
  end

  def test_seach_by_name_scope
    # by first name
    assert_equal 4, Person.seach_by_name('Robert').first.id
    # by middle name
    assert_equal 4, Person.seach_by_name('Vahtang').first.id
    # by mail
    assert_equal 1, Person.seach_by_name(Person.find(1).email).first.id
  end

  def test_in_department_scope
    assert !Person.in_department(1).any?
    assert_equal [1, 2, 3], Person.in_department(2).map(&:id).sort
    assert_equal [4], Person.in_department(3).map(&:id)
  end

  def test_not_in_department_scope
    assert Person.not_in_department(1).map(&:id).include?(4)
    assert !Person.not_in_department(2).map(&:id).include?(1)
  end

  def test_visible?
    if Redmine::VERSION.to_s >= '3.0'
      Member.delete_all
      MemberRole.delete_all

      role = Role.create!(:name => 'role', :users_visibility => 'members_of_visible_projects', :issues_visibility => 'all')

      project1 = Project.find(1)

      person2 = Person.find(2)
      person3 = Person.find(3)

      # There are no joint projects between person2 and person3
      Member.create_principal_memberships(person2, :project_id => project1.id, :role_ids => [role.id])
      assert !person3.visible?(person2)

      # Adds the joint project
      Member.create_principal_memberships(person3, :project_id => project1.id, :role_ids => [role.id])
      assert person3.visible?(person2)
    end
  end

  def test_add_tag
    User.current = nil
    person = Person.find(4)
    assert !person.tags.any?

    # without access
    person.safe_attributes = { 'tag_list' => 'Tag1, Tag2' }
    person.save
    assert !person.reload.tag_list.any?

    # with access
    User.current = Person.find(1)
    person.safe_attributes = { 'tag_list' => 'Tag1, Tag2' }
    person.save
    assert_equal ['Tag1', 'Tag2'], person.reload.tag_list.sort
  end
end
