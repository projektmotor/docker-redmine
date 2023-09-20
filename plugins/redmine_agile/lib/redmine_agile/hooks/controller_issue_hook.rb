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

module RedmineAgile
  module Hooks
    class ControllerIssueHook < Redmine::Hook::ViewListener

      def controller_issues_edit_before_save(context={})
        add_agile_journal_details(context)
      end

      def controller_issues_bulk_edit_before_save(context={})
        add_agile_journal_details(context)
      end

      private

      def add_agile_journal_details(context)
        return false unless context[:issue].project.module_enabled?(:agile)
        # return false unless context[:issue].color
        old_value = Issue.where(id: context[:issue].id).first || context[:issue]
        old_issue_color = old_value.color.to_s
        new_issue_color = context[:issue].color.to_s

        if new_issue_color && !((new_issue_color == old_issue_color) || context[:issue].current_journal.blank?)
          context[:issue].current_journal.details << JournalDetail.new(:property => 'attr',
                                                                       :prop_key => 'color',
                                                                       :old_value => old_issue_color,
                                                                       :value => new_issue_color)
        end
        # save changes for story points to journal
        old_sp = old_value.story_points
        new_sp = context[:issue].story_points
        if !((new_sp == old_sp) || context[:issue].current_journal.blank?)
          context[:issue].current_journal.details << JournalDetail.new(:property => 'attr',
          :prop_key => 'story_points',
          :old_value => old_sp,
          :value => new_sp)
        end
        old_sp = old_value.agile_data.try(:agile_sprint)
        new_sp = context[:issue].agile_data.try(:agile_sprint)
        if !((new_sp == old_sp) || context[:issue].current_journal.blank?)
          context[:issue].current_journal.details << JournalDetail.new(:property => 'attr',
          :prop_key => 'agile_sprint',
          :old_value => old_sp,
          :value => new_sp)
        end
      end
    end
  end
end
