# encoding: utf-8
#
# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ChecklistTest < ActiveSupport::TestCase
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

  RedmineChecklists::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_checklists).directory + '/test/fixtures/', [:checklists])
  def setup
    RedmineChecklists::TestCase.prepare
    Setting.default_language = 'en'
    @project_1 = Project.find(1)
    @issue_1 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 1,
                            :status_id => 1, :priority => IssuePriority.first,
                            :subject => 'Invoice Issue 1')
    @checklist_1 = Checklist.create(:subject => 'TEST1', :position => 1, :issue => @issue_1)
  end

  test "should save checklist" do
    assert @checklist_1.save, "Checklist save error"
  end

  test "should not save checklist without subject" do
    @checklist_1.subject = nil
    assert !@checklist_1.save, "Checklist save with nil subject"
  end

  test "should not save checklist without position" do
    @checklist_1.position = nil
    assert !@checklist_1.save, "Checklist save with nil position"
  end

  test "should not save checklist with non integer position" do
    @checklist_1.position = "string"
    assert !@checklist_1.save, "Checklist save with non ingeger position"
  end

  test "should return project info" do
    assert_equal @project_1, @checklist_1.project, "Helper project broken"
  end

  test "should return info about checklist" do
    assert_equal "[ ] #{@checklist_1.subject}", @checklist_1.info, "Helper info broken"
    @checklist_1.is_done = 1
    assert_equal "[x] #{@checklist_1.subject}", @checklist_1.info, "Helper info broken"
  end

  def test_should_correct_recalculate_rate
    issues = [
      [Issue.create(project_id: 1, tracker_id: 1, author_id: 1, status_id: 1, priority: IssuePriority.first, subject: "TI #1", done_ratio: 0,
                    checklists_attributes: {
                      '0' => { subject: 'item 1', is_done: false },
                      '1' => { subject: 'item 2', is_done: false },
                      '2' => { subject: 'item 3', is_done: true },
                    }),
       30],
      [Issue.create(project_id: 1, tracker_id: 1, author_id: 1, status_id: 1, priority: IssuePriority.first, subject: "TI #2", done_ratio: 0,
                    checklists_attributes: {
                      '0' => { subject: 'item 1', is_done: false },
                      '1' => { subject: 'item 2', is_done: true },
                      '2' => { subject: 'item 3', is_done: true },
                    }),
       60],
       [Issue.create(project_id: 1, tracker_id: 1, author_id: 1, status_id: 1, priority: IssuePriority.first, subject: "TI #3", done_ratio: 0,
                     checklists_attributes: {
                       '0' => { subject: 'item 1', is_done: true },
                       '1' => { subject: 'item 2', is_done: true },
                       '2' => { subject: 'item 3', is_done: true },
                     }),
       100],
       [Issue.create(project_id: 1, tracker_id: 1, author_id: 1, status_id: 1, priority: IssuePriority.first, subject: "TI #4", done_ratio: 0,
                     checklists_attributes: {
                       '0' => { subject: 'item 1', is_done: false },
                       '1' => { subject: 'item 2', is_done: false },
                       '2' => { subject: 'section 1', is_done: true, is_section: true },
                       '3' => { subject: 'item 3', is_done: true },
                     }),
       30],
       [Issue.create(project_id: 1, tracker_id: 1, author_id: 1, status_id: 1, priority: IssuePriority.first, subject: "TI #5", done_ratio: 0,
        checklists_attributes: {
          '0' => { subject: 'section 1', is_done: true, is_section: true }
        }),
       0]
    ]

    with_checklists_settings('issue_done_ratio' => '1') do
      issues.each do |issue, after_ratio|
        assert_equal 0, issue.done_ratio
        Checklist.recalc_issue_done_ratio(issue.id)
        issue.reload
        assert_equal after_ratio, issue.done_ratio
      end
    end
  ensure
    issues.each { |issue, ratio| issue.destroy }
  end
end
