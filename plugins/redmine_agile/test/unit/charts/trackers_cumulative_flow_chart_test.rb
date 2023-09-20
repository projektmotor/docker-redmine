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

class TrackersCumulativeFlowChartTest < ActiveSupport::TestCase
  fixtures :users, :projects, :trackers, :enumerations, :issue_statuses, :issue_categories

  def setup
    @user = User.first
    @tracker1 = Tracker.find(1)
    @tracker2 = Tracker.find(2)
    @tracker3 = Tracker.find(3)
    @project = Project.first_or_create(name: 'TrackersCumulativeFlowChartTest', identifier: 'trackercumulativeflowcharttest')
    @project.trackers << @tracker1 unless @project.trackers.include?(@tracker1)
    @project.trackers << @tracker2 unless @project.trackers.include?(@tracker2)
    @project.trackers << @tracker3 unless @project.trackers.include?(@tracker3)
    @new_status = IssueStatus.where(name: 'New').first
    @closed_status = IssueStatus.where(name: 'Closed').first
  end

  def test_returned_data
    chart_data_cases.each do |test_case|
      test_case_issues = test_case[:issues].call
      test_case[:inerval_data].each do |case_interval|
        #puts "TrackersCumulativeFlowChartTest case - #{case_interval[:name]}"
        chart_data = RedmineAgile::Charts::TrackersCumulativeFlowChart.data(test_case_issues, case_interval[:options])
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
        name: 'every month issues',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        title: 'Cumulative flow',
        internals: {
          day: {
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), interval_size: 'day' },
            result: [{ type: 'line', data: [0, 0], label: 'Support request'},
                     { type: 'line', data: [0, 0], label: 'Feature request'},
                     { type: 'line', data: [0, 0], label: 'Bug'}]
          },
          month: {
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), interval_size: 'week' },
            result: [{ type: 'line', data: [1, 1, 1, 1, 1], label: 'Support request'},
                     { type: 'line', data: [2, 2, 2, 2, 2], label: 'Feature request'},
                     { type: 'line', data: [1, 1, 1, 1, 1], label: 'Bug'}]
          },
          year: {
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4], label: 'Support request'},
                     { type: 'line', data: [1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4], label: 'Feature request'},
                     { type: 'line', data: [0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4], label: 'Bug'}]
          },
          between: {
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [{ type: 'line', data: [3, 3, 3, 4, 4, 4, 4], label: 'Support request'},
                     { type: 'line', data: [3, 3, 4, 4, 4, 4, 4], label: 'Feature request'},
                     { type: 'line', data: [2, 3, 3, 3, 4, 4, 4], label: 'Bug'}]
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
    issue = Issue.create!(tracker: [@tracker1, @tracker2, @tracker3].rotate(month).first,
                          project: @project,
                          author: @user,
                          subject: "Issue ##{month}",
                          status: month != 1 ? @closed_status : @new_status,
                          estimated_hours: month * 2)
    issue.reload
    issue.create_agile_data(story_points: month * 3)
    issue.update(created_on: "2019-#{pmstring}-01 09:00", closed_on: "2019-#{mstring}-01 11:00")
    issue.id
  end
end
