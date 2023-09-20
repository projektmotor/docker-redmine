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

require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Redmine::ApiTest::AgileDataTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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

  RedmineAgile::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_agile).directory + '/test/fixtures/', [:agile_data])

  def setup
    Setting.rest_api_enabled = '1'
    EnabledModule.create(:project => Project.find(1), :name => 'agile')
    RedmineAgile::TestCase.prepare
  end

  test 'GET agile_data' do
    compatible_api_request :get, '/issues/1/agile_data.xml', {}, credentials('admin')
    assert_match 'application/xml', @response.content_type
    assert_equal '200', @response.code
  end

  test 'GET missied id' do
    missied_id = Issue.order(:id).last.id
    compatible_api_request :get, "/issues/#{missied_id}/agile_data.xml", {}, credentials('admin')
    assert_match 'application/xml', @response.content_type
    assert ['401', '403'].include?(@response.code)
  end
end
