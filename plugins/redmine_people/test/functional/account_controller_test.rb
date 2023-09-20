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

class AccountControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :roles
  fixtures :email_addresses if Redmine::VERSION.to_s > '3.0'

  def setup
    User.current = nil
  end

  def test_post_register_with_registration_on
    @request.session[:user_id] = nil

    with_settings :self_registration => '3' do
      assert_difference 'User.count' do
        compatible_request :post, :register, :user => { :login => 'register',
                                                        :password => 'secret123',
                                                        :password_confirmation => 'secret123',
                                                        :firstname => 'John',
                                                        :lastname => 'Doe',
                                                        :mail => 'register@example.com' }
        assert_redirected_to '/my/account'
      end
      user = User.order('id DESC').first
      assert_equal 'register', user.login
      assert_equal 'John', user.firstname
      assert_equal 'Doe', user.lastname
      assert_equal 'register@example.com', user.mail
      assert user.check_password?('secret123')
      assert user.active?
    end
  end

end
