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

class UsersControllerTest < ActionController::TestCase
  fixtures :users,
           :roles,
           :members,
           :member_roles

  fixtures :email_addresses if Redmine::VERSION.to_s > '3.0'

  def setup
    @user = User.find(1)
    @request.session[:user_id] = @user.id
  end
  def test_get_index_with_colors
    with_agile_settings 'color_on' => 'user' do
      compatible_request :get, :edit, :id => @user.id
      assert_response :success
      assert_select '#user_agile_color_attributes_color', 1
    end
  end if Redmine::VERSION.to_s > '2.4'

  def test_save_user_with_color
    with_agile_settings 'color_on' => 'user' do
      compatible_request :post, :update, :id => @user.id,
        :user => { :agile_color_attributes => { :color => AgileColor::AGILE_COLORS[:red] } }
      assert_equal AgileColor::AGILE_COLORS[:red], @user.reload.color
    end
  end if Redmine::VERSION.to_s > '2.4'
end
