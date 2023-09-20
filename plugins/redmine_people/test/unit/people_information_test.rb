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

class PeopleInformationTest < ActiveSupport::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_information, :departments])

  def setup
    @person_3 = PeopleInformation.find(3)
  end

  def test_validate_manager
    # Can not be manager to itself
    @person_3.manager_id = 3
    assert !@person_3.valid?

    # Can not be manager to each other
    @person_3.manager_id = 4
    assert !@person_3.valid?

    # Can not be manager to null person
    @person_3.manager_id = 999
    assert !@person_3.valid?

    p = PeopleInformation.new
    p.manager_id = 2
    assert p.valid?

    @person_3.manager_id = 2
    assert @person_3.valid?
  end
end
