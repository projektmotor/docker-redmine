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

class ProjectsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles


  def setup
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'agile')
    EnabledModule.create(:project => @project_2, :name => 'agile')
    @request.session[:user_id] = 1
  end
  def test_get_index_with_colors
    with_agile_settings 'color_on' => 'project' do
      compatible_request :get, :settings, :id => @project_1
      assert_response :success
      assert_select '#project_agile_color_attributes_color', 1
    end
  end


  def test_save_project_with_color
    with_agile_settings 'color_on' => 'project' do
      compatible_request :post, :update, :id => @project_1, :project => { :name => 'Test changed name',
        :agile_color_attributes => { :color => AgileColor::AGILE_COLORS[:red] } }
      @project_1.reload
      assert_equal 'Test changed name', @project_1.name
      assert_equal AgileColor::AGILE_COLORS[:red], @project_1.color
    end
  end
end
