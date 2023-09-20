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

class Redmine::ApiTest::AgileSprintTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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
    Setting.rest_api_enabled = '1'
    RedmineAgile::TestCase.prepare
    project = Project.find(1)

    ['agile', 'agile_backlog'].each do |p_module|
      EnabledModule.create(project: project, name: p_module)
    end
  end

  test 'GET agile_sprints' do
    compatible_api_request :get, '/projects/1/agile_sprints.xml', {}, credentials('admin')
    assert_match 'application/xml', @response.content_type
    assert_equal '200', @response.code
  end

  test 'GET agile_sprint' do
    compatible_api_request :get, '/projects/1/agile_sprints/1.xml', {}, credentials('admin')
    assert_match 'application/xml', @response.content_type
    assert_equal '200', @response.code
  end

  test 'GET missied id' do
    missied_id = Project.order(:id).last.id
    compatible_api_request :get, "/projects/#{missied_id}/agile_sprints.xml", {}, credentials('admin')
    assert_match 'application/xml', @response.content_type
    assert ['401', '403'].include?(@response.code)
  end

  def test_put_agile_spints_1_xml
    @parameters = { :agile_sprint => {"name"=>"Sprint #1",
                                      "description"=>"",
                                      "status"=>"0",
                                      "sharing"=>"0",
                                      "start_date"=> (Time.now + 1.day).to_s,
                                      "end_date"=> (Time.now + 2.day).to_s }
    }

    compatible_api_request :put, '/projects/1/agile_sprints/1.xml', @parameters, credentials('admin')
    assert_equal '302', @response.code
    sprint = AgileSprint.find(1)
    assert_equal 'Sprint #1', sprint.name
  end

  def test_create_agile_spint_json
    @parameters = { :agile_sprint => {"name"=>"Sprint last",
                                      "description"=>"",
                                      "status"=>"0",
                                      "sharing"=>"0",
                                      "start_date"=> (Time.now + 31.day).to_s,
                                      "end_date"=> (Time.now + 32.day).to_s } 
    }

    assert_equal 2, AgileSprint.count
    compatible_api_request :post, '/projects/1/agile_sprints.json', @parameters, credentials('admin')
    assert_equal '201', @response.code
    sprint = AgileSprint.last
    assert_equal 'Sprint last', sprint.name
    assert_equal 3, AgileSprint.count
  end
end
