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

class AgileChartsControllerTest < ActionController::TestCase
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

  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @issue = @project.issues.first

    EnabledModule.create(project: @project, name: 'agile')

    @charts = RedmineAgile::Charts::Helper::AGILE_CHARTS.keys
    @charts_with_units = RedmineAgile::Charts::Helper::CHARTS_WITH_UNITS
  end

  def test_get_show
    should_get_show
    should_get_show project_id: @project.identifier
  end

  def test_get_show_with_period
    should_get_show({ f: ['issue_id', ''], op: { 'issue_id' => '*' } })
    should_get_show({ f: ['issue_id', ''], op: { 'issue_id' => '*' }, project_id: @project.identifier })
  end

  def test_charts_by_default_params
    @charts.each { |chart| check_chart(chart: chart, project_id: @project.identifier) }
  end

  def test_charts_with_chart_unit
    @charts_with_units.each do |chart|
      RedmineAgile::Charts::Helper::CHART_UNITS.each do |chart_unit, label|
        check_chart chart: chart, project_id: @project.identifier, chart_unit: chart_unit
      end
    end
  end

  def test_charts_by_different_time_intervals
    @charts.each do |chart|
      RedmineAgile::Charts::AgileChart::TIME_INTERVALS.each do |interval|
        check_chart chart: chart, project_id: @project.identifier, interval_size: interval
      end
    end
  end

  def test_charts_by_different_periods_and_time_intervals
    @charts.each do |chart|
      RedmineAgile::Charts::AgileChart::TIME_INTERVALS.each do |interval|
        params = {
          chart: chart,
          project_id: @project.identifier,
          interval_size: interval,
          set_filter: 1,
          f: ['chart_period']
        }

        check_chart params.merge(op: { chart_period: '=' }, v: { chart_period: ['2014-01-01'] })
        check_chart params.merge(op: { chart_period: '>=' }, v: { chart_period: ['2014-01-01'] })
        check_chart params.merge(op: { chart_period: '<=' }, v: { chart_period: ['2019-01-01'] })
        check_chart params.merge(op: { chart_period: '><' }, v: { chart_period: ['2014-01-01', '2018-12-31'] })
        check_chart params.merge(op: { chart_period: '>t-' }, v: { chart_period: [99] })
        check_chart params.merge(op: { chart_period: '<t-' }, v: { chart_period: [99] })
        check_chart params.merge(op: { chart_period: '><t-' }, v: { chart_period: [99] })
        check_chart params.merge(op: { chart_period: 't-' }, v: { chart_period: [99] })
        check_chart params.merge(op: { chart_period: 't' })
        check_chart params.merge(op: { chart_period: 'ld' })
        check_chart params.merge(op: { chart_period: 'w' })
        check_chart params.merge(op: { chart_period: 'lw' })
        check_chart params.merge(op: { chart_period: 'l2w' })
        check_chart params.merge(op: { chart_period: 'm' })
        check_chart params.merge(op: { chart_period: 'lm' })
        check_chart params.merge(op: { chart_period: 'y' })
        check_chart params.merge(op: { chart_period: '!*' })
        check_chart params.merge(op: { chart_period: '*' })
      end
    end
  end

  def test_render_charts
    @charts.each do |chart|
      should_get_render_chart chart: chart, chart_unit: 'issues'
    end
  end

  def test_charts_with_version
    @charts.each do |chart|
      should_get_render_chart chart: chart, version_id: 2
      should_get_render_chart chart: chart, version_id: 2, project_id: @project.identifier
    end
  end

  def test_charts_with_version_and_chart_unit
    @charts_with_units.each do |chart|
      RedmineAgile::Charts::Helper::CHART_UNITS.each do |chart_unit, label|
        should_get_render_chart chart: chart, version_id: 2, chart_unit: chart_unit
      end
    end
  end

  def test_issues_burndown_chart_when_first_issue_later_then_due_date
    new_version = Version.create!(name: 'Some new vesion', effective_date: (Date.today - 10.days), project_id: @project.id)
    issue = Issue.create!(
      project_id: @project.id,
      tracker_id: 1,
      subject: 'test_issues_burndown_chart_when_first_issue_later_then_due_date',
      author_id: 2,
      start_date: Date.today
    )
    new_version.fixed_issues << issue.reload

    should_get_render_chart chart: RedmineAgile::Charts::Helper::BURNDOWN_CHART, project_id: @project.identifier, version_id: new_version.id
  end
  def test_agile_chart_queries_visibility
    me_chart = AgileChartsQuery.new(name: 'Only for me chart',
                                    options: { chart: 'burndown_chart', interval_size: 'day', chart_unit: 'issues' },
                                    visibility: 0)
    me_chart.user_id = 1
    me_chart.save

    another_chart = AgileChartsQuery.new(name: 'Another private chart',
                                         options: { chart: 'burndown_chart', interval_size: 'day', chart_unit: 'issues' },
                                         visibility: 0)
    another_chart.user_id = 2
    another_chart.save

    compatible_request :get, :show
    assert_response :success
    assert_select 'ul.agile-chart-queries li', 1
    assert_match /Only for me chart/, @response.body
    assert_no_match /Another private chart/, @response.body
  ensure
    [me_chart, another_chart].each(&:destroy)
  end

  def test_get_show_chart_with_open_target_version
    current_version = @issue.fixed_version
    @issue.update(fixed_version: Version.open.first)

    should_get_render_chart project_id: @project.identifier, chart: 'burndown_chart',
                                                             f: ['version_status'],
                                                             op: { 'version_status' => '=' },
                                                             v: { 'version_status' => ['open'] }
    ensure
    @issue.update(fixed_version: current_version)
  end

  private

  def should_get_show(parameters = {})
    compatible_request :get, :show, parameters
    assert_response :success
    assert_select 'canvas#agile-chart', 1
  end

  def should_get_render_chart(parameters = {})
    compatible_xhr_request :get, :render_chart, parameters
    assert_response :success
    assert_match 'application/json', response.content_type

    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_equal parameters[:chart], json['chart']
    if parameters[:chart_unit]
      assert_equal parameters[:chart_unit], json['chart_unit']
    end
  end

  def check_chart(parameters = {})
    should_get_show parameters
    should_get_render_chart parameters.slice(:chart, :project_id)
  end
end
