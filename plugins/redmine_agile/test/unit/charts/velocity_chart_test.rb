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

class VelocityChartChartTest < ActiveSupport::TestCase
  fixtures :users, :projects, :trackers, :enumerations, :issue_statuses, :issue_categories

  def setup
    @user = User.first
    @tracker = Tracker.first
    @project = Project.first_or_create(name: 'VelocityChartChartTest', identifier: 'velocitycharttest')
    @project.trackers << @tracker unless @project.trackers.include?(@tracker)
    @new_status = IssueStatus.where(name: 'New').first
    @closed_status = IssueStatus.where(name: 'Closed').first
  end

  def test_returned_data
    chart_data_cases.each do |test_case|
      test_case_issues = test_case[:issues].call
      test_case[:inerval_data].each do |case_interval|
        #puts "VelocityChartChartTest case - #{case_interval[:name]}"
        chart_data = RedmineAgile::Charts::VelocityChart.data(test_case_issues, case_interval[:options])
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
        internals: {
          day: {
            title: 'Velocity',
            dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), interval_size: 'day' },
            result: [
                     { type: 'bar', data: [0, 2.0], label: 'Created' },
                     { type: 'line', data: [0.0, 2.0], label: 'Created trendline' },
                     { type: 'bar', data: [0, 1.0], label: 'Closed' },
                     { type: 'line', data: [0.0, 1.0], label: 'Closed trendline' }
                   ]
          },
          month: {
            title: 'Average velocity',
            dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), interval_size: 'week' },
            result: [
                     { type: 'bar', data: [1.0, 0, 0, 0, 0], label: 'Created' },
                     { type: 'line', data: [0.6000000000000001, 0.4, 0.19999999999999996, 0.0], label: 'Created trendline' },
                     { type: 'bar', data: [1.0, 0, 0, 0, 0], label: 'Closed' },
                     { type: 'line', data: [0.6000000000000001, 0.4, 0.19999999999999996, 0.0], label: 'Closed trendline' }
                   ]
          },
          year: {
            title: 'Average velocity',
            dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [
                     { type: 'bar', data: [2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0], label: 'Created' },
                     { type: 'line', data: [1.4835164835164836, 1.39010989010989, 1.2967032967032965, 1.2032967032967032, 1.10989010989011, 1.0164835164835164, 0.923076923076923, 0.8296703296703296, 0.7362637362637362, 0.6428571428571428, 0.5494505494505495, 0.456043956043956, 0.36263736263736246], label: 'Created trendline' },
                     { type: 'bar', data: [1.0, 0, 1.0, 0, 1.0, 0, 1.0, 0, 1.0, 0, 1.0, 0, 0], label: 'Closed' },
                     { type: 'line', data: [0.6593406593406593, 0.6263736263736264, 0.5934065934065934, 0.5604395604395604, 0.5274725274725275, 0.49450549450549447, 0.4615384615384615, 0.42857142857142855, 0.3956043956043956, 0.3626373626373626, 0.32967032967032966, 0.29670329670329665, 0.2637362637362637], label: 'Closed trendline' }
                   ]
          },
          between: {
            title: 'Average velocity',
            dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), interval_size: 'month' },
            result: [
                     { type: 'bar', data: [1.0, 1.0, 1.0, 1.0, 1.0, 0, 0], label: 'Created' },
                     { type: 'line', data: [1.25, 1.0714285714285714, 0.8928571428571429, 0.7142857142857143, 0.5357142857142857, 0.3571428571428572, 0.1785714285714286], label: 'Created trendline' },
                     { type: 'bar', data: [1.0, 0, 1.0, 0, 1.0, 0, 0], label: 'Closed' },
                     { type: 'line', data: [0.75, 0.6428571428571428, 0.5357142857142857, 0.42857142857142855, 0.3214285714285714, 0.2142857142857143, 0.1071428571428571], label: 'Closed trendline' }
                   ]
          }
        }
      },
      {
        name: 'every month issues by hours',
        issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
        internals: {
          day: {
              title: 'Velocity',
              dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'hours', interval_size: 'day' },
              result: [
                       { type: 'bar', data: [0, 6.0], label: 'Created' },
                       { type: 'line', data: [0.0, 6.0], label: 'Created trendline' },
                       { type: 'bar', data: [0, 2.8], label: 'Closed' },
                       { type: 'line', data: [2.8000000000000003], label: 'Closed trendline' }
                     ]
          },
          month: {
              title: 'Average velocity',
              dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'hours', interval_size: 'week' },
              result: [
                       { type: 'bar', data: [8.0, 0, 0, 0, 0], label: 'Created' },
                       { type: 'line', data: [4.800000000000001, 3.2, 1.5999999999999996, 0.0], label: 'Created trendline' },
                       { type: 'bar', data: [9.2, 0, 0, 0, 0], label: 'Closed' },
                       { type: 'line', data: [5.52, 3.6799999999999993, 1.839999999999999], label: 'Closed trendline' }
                     ]
          },
          year: {
              title: 'Average velocity',
              dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
              result: [
                       { type: 'bar', data: [6.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 0, 0], label: 'Created' },
                       { type: 'line', data: [10.21978021978022, 10.516483516483516, 10.813186813186814, 11.10989010989011, 11.406593406593407, 11.703296703296704, 12.0, 12.296703296703297, 12.593406593406593, 12.89010989010989, 13.186813186813186, 13.483516483516484, 13.780219780219781], label: 'Created trendline' },
                       { type: 'bar', data: [2.8, 0, 9.2, 0, 17.2, 0, 26.8, 0, 38.0, 0, 22.0, 0, 0], label: 'Closed' },
                       { type: 'line', data: [6.417582417582418, 6.835164835164835, 7.252747252747253, 7.670329670329671, 8.087912087912088, 8.505494505494505, 8.923076923076923, 9.340659340659341, 9.758241758241759, 10.175824175824175, 10.593406593406595, 11.010989010989011, 11.428571428571429], label: 'Closed trendline' }
                     ]
          },
          between: {
              title: 'Average velocity',
              dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'hours', interval_size: 'month' },
              result: [
                       { type: 'bar', data: [16.0, 18.0, 20.0, 22.0, 24.0, 0, 0], label: 'Created' },
                       { type: 'line', data: [22.857142857142858, 20.0, 17.142857142857146, 14.285714285714286, 11.428571428571429, 8.571428571428573, 5.714285714285715], label: 'Created trendline' },
                       { type: 'bar', data: [26.8, 0, 38.0, 0, 22.0, 0, 0], label: 'Closed' },
                       { type: 'line', data: [22.728571428571428, 19.285714285714285, 15.842857142857143, 12.4, 8.957142857142859, 5.514285714285716, 2.071428571428573], label: 'Closed trendline' }
                     ]
          }
        }
      },
      {
          name: 'every month issues by sp',
          issues: Proc.new { Issue.where(id: (1..12).map { |month| create_issue_data(month) }) },
          internals: {
              day: {
                  title: 'Velocity',
                  dates: { date_from: Date.parse('2018-12-31'), date_to: Date.parse('2019-01-01'), chart_unit: 'story_points', interval_size: 'day' },
                  result: [
                           { type: 'bar', data: [0, 30.0], label: 'Created' },
                           { type: 'line', data: [0.0, 30.0], label: 'Created trendline' },
                           { type: 'bar', data: [0, 14.0], label: 'Closed' },
                           { type: 'line', data: [0.0, 14.0], label: 'Closed trendline' }
                         ]
              },
              month: {
                  title: 'Average velocity',
                  dates: { date_from: Date.parse('2019-03-01'), date_to: Date.parse('2019-03-31'), chart_unit: 'story_points', interval_size: 'week' },
                  result: [
                           { type: 'bar', data: [40.0, 0, 0, 0, 0], label: 'Created' },
                           { type: 'line', data: [24.0, 16.0, 8.0, 0.0], label: 'Created trendline' },
                           { type: 'bar', data: [46.0, 0, 0, 0, 0], label: 'Closed' },
                           { type: 'line', data: [27.599999999999998, 18.4, 9.2, 0.0], label: 'Closed trendline' }
                         ]
              },
              year: {
                  title: 'Average velocity',
                  dates: { date_from: Date.parse('2019-01-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
                  result: [
                           { type: 'bar', data: [30.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 0, 0], label: 'Created' },
                           { type: 'line', data: [51.098901098901095, 52.58241758241758, 54.065934065934066, 55.54945054945055, 57.03296703296703, 58.51648351648352, 60.0, 61.48351648351648, 62.967032967032964, 64.45054945054945, 65.93406593406593, 67.41758241758242, 68.90109890109889], label: 'Created trendline' },
                           { type: 'bar', data: [14.0, 0, 46.0, 0, 86.0, 0, 134.0, 0, 190.0, 0, 110.0, 0, 0], label: 'Closed' },
                           { type: 'line', data: [32.08791208791209, 34.175824175824175, 36.26373626373626, 38.35164835164835, 40.43956043956044, 42.527472527472526, 44.61538461538461, 46.7032967032967, 48.79120879120879, 50.879120879120876, 52.967032967032964, 55.05494505494506, 57.142857142857146], label: 'Closed trendline' }
                         ]
              },
              between: {
                  title: 'Average velocity',
                  dates: { date_from: Date.parse('2019-07-01'), date_to: Date.parse('2019-12-31'), chart_unit: 'story_points', interval_size: 'month' },
                  result: [
                           { type: 'bar', data: [80.0, 90.0, 100.0, 110.0, 120.0, 0, 0], label: 'Created' },
                           { type: 'line', data: [114.28571428571429, 100.00000000000001, 85.71428571428572, 71.42857142857144, 57.14285714285715, 42.85714285714286, 28.571428571428584], label: 'Created trendline' },
                           { type: 'bar', data: [134.0, 0, 190.0, 0, 110.0, 0, 0], label: 'Closed' },
                           { type: 'line', data: [113.64285714285714, 96.42857142857143, 79.21428571428572, 62.0, 44.78571428571428, 27.57142857142857, 10.357142857142861], label: 'Closed trendline' }
                         ]
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
                          result: { title: interval_data[:title], datasets: interval_data[:result] }
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
                          done_ratio: (month.even? && month < 11) ? month * 10 : 0,
                          status: month.odd? ? @closed_status : @new_status,
                          estimated_hours: month * 2)
    issue.reload
    issue.create_agile_data(story_points: month * 10)
    issue.update(created_on: "2019-#{pmstring}-01 09:00", closed_on: "2019-#{mstring}-01 11:00")
    issue.id
  end
end
