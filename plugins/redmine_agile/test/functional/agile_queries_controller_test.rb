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
class AgileQueriesControllerTest < ActionController::TestCase
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

  RedmineAgile::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_agile).directory + '/test/fixtures/', [:queries])

  def setup
    RedmineAgile::TestCase.prepare
  end

  def test_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_match /Agile boards/, @response.body
  end

  def test_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success
    assert_match /New agile board/, @response.body
  end

  def test_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => create_agile_query.id
    assert_response :success
    assert_match /Edit agile board/, @response.body
  end

  def test_get_edit_for_public_board
    @request.session[:user_id] = 2
    compatible_request :get, :edit, id: AgileQuery.find(102).id # Public board query
    assert_response :success
    assert_match /Edit agile board/, @response.body
  end

  def test_post_create
    @request.session[:user_id] = 1
    params = { :query => { :name => 'Test', :group_by => '' },
               :query_is_for_all => '1', :default_columns => '1', :f => ['status_id', ''],
               :op => { 'status_id' => 'o' }, :c => ['tracker', 'assigned_to'] }
    if Redmine::VERSION.to_s < '2.4'
      params[:query][:is_public] = true
    else
      params[:query][:visibility] = '0'
    end
    assert_difference 'AgileQuery.count' do
      compatible_request :post, :create, params
      assert_response :redirect
    end
  end

  def test_put_update
    @request.session[:user_id] = 1
    params = { :query => { :name => 'Test changed', :group_by => ''}, :id => create_agile_query.id}
    Redmine::VERSION.to_s < '2.4' ? params[:query][:is_public] = true : params[:query][:visibility] = '0'
    compatible_request :put, :update, params
    assert_response :redirect
  end
  def test_save_wip_options
    @request.session[:user_id] = 1
    wp_params = { '1' => '5', '2' => '5', '3' => '5', '4' => '5', '5' => '', '6' => '' }
    params = { :query => { :name => 'Test', :group_by => '', :is_default => '1' },
               :query_is_for_all => '1',
               :default_columns => '1',
               :f_status => ['1', '2', '3', '4'],
               :wp => wp_params,
               :op => { 'status_id' => 'o' },
               :c => ['tracker', 'assigned_to'] }
    compatible_request :post, :create, params
    query = Query.last
    assert_equal true, query.is_default?
    assert_equal wp_params, query.options[:wp]
    assert_equal ['1', '2', '3', '4'], query.options[:f_status]
  end if Redmine::VERSION.to_s > '2.4'

  def test_post_create_with_sprint_and_blacklog
    @request.session[:user_id] = 1
    params = { :query => { :name => 'Sprint+Backlog', :group_by => '' },
               :query_is_for_all => '1', :default_columns => '1', :f => ['status_id', ''],
               :op => { 'status_id' => 'o' }, :c => ['tracker', 'assigned_to'],
               :sprints_enabled => '1', :backlog_column => '1' }
    assert_difference 'AgileQuery.count' do
      compatible_request :post, :create, params
      assert_response :redirect
    end
    query = AgileQuery.last
    assert_equal 1, query.sprints_enabled.to_i
    assert_equal 1, query.backlog_column.to_i
  end

private

  def create_agile_query
    query = AgileQuery.new(:name => 'Board for specific project',
                           :user_id => 1,
                           :project_id => 1,
                           :filters => { :tracker_id => { :values => ['3'], :operator => '=' } })
    Redmine::VERSION.to_s < '2.4' ? query.is_public = false : query.visibility = 2
    query.save
    query
  end

end
