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
 
class QueriesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineAgile::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_agile).directory + '/test/fixtures/', [:agile_data, :agile_sprints])

  def setup
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'agile')
    EnabledModule.create(:project => @project_2, :name => 'agile')
    @request.session[:user_id] = 1
  end

  def test_get_index_with_agile_sprints
    compatible_request :get, :filter,
      :type => "IssueQuery", :name => "agile_sprints"
    assert_response :success
    json = ActiveSupport::JSON.decode(response.body)
    assert_include ["eCookbook - Test sprint 1", "1", "Open"], json
  end  


end if Redmine::VERSION.to_s > '3.4'
