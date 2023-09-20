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

require File.expand_path('../../../test_helper', __FILE__)

class BurndownChartTest < ActiveSupport::TestCase
  fixtures :users, :projects, :trackers, :enumerations, :issue_statuses, :issue_categories

  def setup
    @user = User.first
    @tracker = Tracker.first
    @project = Project.first_or_create(name: 'BurndownChartTest', identifier: 'burndowncharttest')
    @project.trackers << @tracker unless @project.trackers.include?(@tracker)
    @open_status = IssueStatus.where(is_closed: false).first
    @closed_status = IssueStatus.where(is_closed: true).first
  end

  def test_returned_data
    chart_data_cases.each do |test_case|
      test_case_issues = test_case[:issues].call
      test_case[:inerval_data].each do |case_interval|
        # puts "BurndownChartTest case - #{case_interval[:name]}"
        chart_data = RedmineAgile::Charts::BurndownChart.data(test_case_issues, case_interval[:options])
        assert_equal case_interval[:result], extract_values(chart_data)
      end
      test_case_issues.destroy_all
    end
  ensure
    @project.issues.destroy_all
    @project.destroy
  end

  private

  def extract_values(chart_data)
    { title: chart_data[:title], datasets: chart_data[:datasets].map { |data| data.slice(:type, :data, :label) } }
  end

  def chart_data_cases
    data_cases = [
      {
        name: 'every month issues by issues',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Issues burndown',
        internals: {
          day: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-01-01'), interval_size: 'day' },
            result: [{ type: 'line', data: [12, 11], label: 'Actual'},
                     { type: 'line', data: [12, 0], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), interval_size: 'week' },
            result: [{ type: 'line', data: [10, 9, 9, 9, 9, 9], label: 'Actual' },
                     { type: 'line', data: [10.0, 7.5, 5.0, 2.5, 0], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1, 1], label: 'Actual' },
                     { type: 'line', data: [12.0, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [6, 5, 4, 3, 2, 1, 1, 1], label: 'Actual' },
                     { type: 'line', data: [6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0], label: 'Ideal' }]
          }
        }
      },
      {
        name: 'every month issues by SP',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Story points burndown',
        internals: {
          day: {
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'story_points', interval_size: 'day' },
            result: [{ type: 'line', data: [234.0, 231.0, 231.0], label: 'Actual'},
                     { type: 'line', data: [234.0, 0], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'story_points', interval_size: 'week' },
            result: [{ type: 'line', data: [216.0, 216.0, 216.0, 216.0, 216.0, 216.0], label: 'Actual' },
                     { type: 'line', data: [216.0, 162.0, 108.0, 54.0, 0], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
            result: [{ type: 'line', data: [225.0, 225.0, 216.0, 204.0, 189.0, 171.0, 150.0, 126.0, 99.0, 69.0, 36.0, 36.0, 36.0, 36.0], label: 'Actual' },
                     { type: 'line', data: [225.0, 206.25, 187.5, 168.75, 150.0, 131.25, 112.5, 93.75, 75.0, 56.25, 37.5, 18.75, 0], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
            result: [{ type: 'line', data: [126.0, 126.0, 99.0, 69.0, 36.0, 36.0, 36.0, 36.0], label: 'Actual' },
                     { type: 'line', data: [126.0, 105.0, 84.0, 63.0, 42.0, 21.0, 0], label: 'Ideal' }]
          }
        }
      },
      {
        name: 'every month issues by Hours',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Hours burndown',
        internals: {
          day: {
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'hours', interval_size: 'day' },
            result: [{ type: 'line', data: [156.0, 154.0, 154.0], label: 'Actual'},
                     { type: 'line', data: [156.0, 0], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'hours', interval_size: 'week' },
            result: [{ type: 'line', data: [144.0, 144.0, 144.0, 144.0, 144.0, 144.0], label: 'Actual' },
                     { type: 'line', data: [144.0, 108.0, 72.0, 36.0, 0], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
            result: [{ type: 'line', data: [150.0, 150.0, 144.0, 136.0, 126.0, 114.0, 100.0, 84.0, 66.0, 46.0, 24.0, 24.0, 24.0, 24.0], label: 'Actual' },
                     { type: 'line', data: [150.0, 137.5, 125.0, 112.5, 100.0, 87.5, 75.0, 62.5, 50.0, 37.5, 25.0, 12.5, 0], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
            result: [{ type: 'line', data: [84.0, 84.0, 66.0, 46.0, 24.0, 24.0, 24.0, 24.0], label: 'Actual' },
                     { type: 'line', data: [84.0, 70.0, 56.0, 42.0, 28.0, 14.0, 0], label: 'Ideal' }]
          }
        }
      }
    ]

    test_cases = data_cases.map do |test_case|
      {
        issues: test_case[:issues],
        inerval_data: test_case[:internals].map do |interval_name, interval_data|
                        {
                          name: [test_case[:name], 'interval', interval_name].join(' '),
                          options: { chart_unit: 'issues', interval_size: 'day' }.merge(interval_data[:dates]),
                          result: { title: test_case[:title], datasets: interval_data[:result] }
                        }
                      end
      }
    end

    test_cases
  end

  def create_issue_data(month)
    mstring = month.to_s.rjust(2, '0')
    issue = Issue.create!(tracker: @tracker,
                          project: @project,
                          author: @user,
                          subject: "Issue ##{month}",
                          status: month != 12 ? @closed_status : @open_status,
                          estimated_hours: month * 2)
    issue.reload
    issue.create_agile_data(story_points: month * 3)
    issue.update(created_on: "2019-01-01 09:00", closed_on: "2019-#{mstring}-01 11:00")
    issue.id
  end
end
