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

class BurnupChartTest < ActiveSupport::TestCase
  fixtures :users, :projects, :trackers, :enumerations, :issue_statuses, :issue_categories

  def setup
    @user = User.first
    @tracker = Tracker.first
    @project = Project.first_or_create(name: 'BurnupChartTest', identifier: 'burnupcharttest')
    @project.trackers << @tracker unless @project.trackers.include?(@tracker)
    @open_status = IssueStatus.where(is_closed: false).first
    @closed_status = IssueStatus.where(is_closed: true).first
  end

  def test_returned_data
    with_agile_settings('chart_future_data' => 1) do
      chart_data_cases.each do |test_case|
        test_case_issues = test_case[:issues].call
        test_case[:inerval_data].each do |case_interval|
          # puts "BurnupChartTest case - #{case_interval[:name]}"
          chart_data = RedmineAgile::Charts::BurnupChart.data(test_case_issues, case_interval[:options])
          assert_equal case_interval[:result], extract_values(chart_data)
        end
        test_case_issues.destroy_all
      end
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
        title: 'Issues burnup',
        internals: {
          day: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-01-01'), interval_size: 'day' },
            result: [{ type: 'line', data: [0, 2], label: 'Created'},
                     { type: 'line', data: [0, 0], label: 'Closed' },
                     { type: 'line', data: [0.0, 2], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), interval_size: 'week' },
            result: [{ type: 'line', data: [3, 4, 4, 4, 4, 4], label: 'Created'},
                     { type: 'line', data: [1, 2, 2, 2, 2, 2], label: 'Closed' },
                     { type: 'line', data: [1.0, 1.75, 2.5, 3.25, 4], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 12], label: 'Created'},
                     { type: 'line', data: [0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11], label: 'Closed' },
                     { type: 'line', data: [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [7, 8, 9, 10, 11, 12, 12, 12], label: 'Created'},
                     { type: 'line', data: [5, 6, 7, 8, 9, 10, 11, 11], label: 'Closed' },
                     { type: 'line', data: [5.0, 6.17, 7.33, 8.5, 9.67, 10.83, 12], label: 'Ideal' }]
          }
        }
      },
      {
        name: 'every month issues by SP',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Story points burnup',
        internals: {
          day: {
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'story_points', interval_size: 'day' },
            result: [{ type: 'line', data: [0, 0, 9], label: 'Created'},
                     { type: 'line', data: [0.0, 0.0, 0.0], label: 'Closed' },
                     { type: 'line', data: [0.0, 9], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'story_points', interval_size: 'week' },
            result: [{ type: 'line', data: [18, 30, 30, 30, 30, 30], label: 'Created'},
                     { type: 'line', data: [15.0, 15.0, 15.0, 15.0, 15.0, 15.0], label: 'Closed' },
                     { type: 'line', data: [15.0, 18.75, 22.5, 26.25, 30], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
            result: [{ type: 'line', data: [0, 9, 18, 30, 45, 63, 84, 108, 135, 165, 198, 234, 234, 234], label: 'Created'},
                     { type: 'line', data: [6.0, 6.0, 15.0, 27.0, 42.0, 60.0, 81.0, 105.0, 132.0, 162.0, 195.0, 231.0, 231.0, 231.0], label: 'Closed' },
                     { type: 'line', data: [6.0, 25.0, 44.0, 63.0, 82.0, 101.0, 120.0, 139.0, 158.0, 177.0, 196.0, 215.0, 234], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
            result: [{ type: 'line', data: [84, 108, 135, 165, 198, 234, 234, 234], label: 'Created'},
                     { type: 'line', data: [105.0, 105.0, 132.0, 162.0, 195.0, 231.0, 231.0, 231.0], label: 'Closed' },
                     { type: 'line', data: [105.0, 126.5, 148.0, 169.5, 191.0, 212.5, 234], label: 'Ideal' }]
          }
        }
      },
      {
        name: 'every month issues by Hours',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Hours burnup',
        internals: {
          day: {
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'hours', interval_size: 'day' },
            result: [{ type: 'line', data: [0.0, 6.0, 6.0], label: 'Created'},
                     { type: 'line', data: [0.0, 0.0, 0.0], label: 'Closed' },
                     { type: 'line', data: [0.0, 6.0], label: 'Ideal' }]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'hours', interval_size: 'week' },
            result: [{ type: 'line', data: [12.0, 12.0, 12.0, 12.0, 12.0, 12.0], label: 'Created'},
                     { type: 'line', data: [10.0, 10.0, 10.0, 10.0, 10.0, 10.0], label: 'Closed' },
                     { type: 'line', data: [10.0, 10.5, 11.0, 11.5, 12.0], label: 'Ideal' }]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
            result: [{ type: 'line', data: [0.0, 6.0, 14.0, 24.0, 36.0, 50.0, 66.0, 84.0, 104.0, 126.0, 150.0, 150.0, 150.0, 150.0], label: 'Created'},
                     { type: 'line', data: [4.0, 4.0, 10.0, 18.0, 28.0, 40.0, 54.0, 70.0, 88.0, 108.0, 130.0, 154.0, 154.0, 154.0], label: 'Closed' },
                     { type: 'line', data: [4.0, 16.17, 28.33, 40.5, 52.67, 64.83, 77.0, 89.17, 101.33, 113.5, 125.67, 137.83, 150.0], label: 'Ideal' }]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
            result: [{ type: 'line', data: [56.0, 74.0, 94.0, 116.0, 140.0, 140.0, 140.0, 140.0], label: 'Created'},
                     { type: 'line', data: [70.0, 70.0, 88.0, 108.0, 130.0, 154.0, 154.0, 154.0], label: 'Closed' },
                     { type: 'line', data: [70.0, 81.67, 93.33, 105.0, 116.67, 128.33, 140.0], label: 'Ideal' }]
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
    pmstring = (month > 1 ? month - 1 : month).to_s.rjust(2, '0')
    issue = Issue.create!(tracker: @tracker,
                          project: @project,
                          author: @user,
                          subject: "Issue ##{month}",
                          status: month != 1 ? @closed_status : @open_status,
                          estimated_hours: month * 2)
    issue.reload
    issue.create_agile_data(story_points: month * 3)
    issue.update(created_on: "2019-#{pmstring}-01 09:00", closed_on: "2019-#{mstring}-01 11:00")
    issue.id
  end
end
