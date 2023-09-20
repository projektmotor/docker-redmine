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

module RedmineChecklists
  module Patches
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :details_to_strings_without_checklists, :details_to_strings
          alias_method :details_to_strings, :details_to_strings_with_checklists
        end
      end


      module InstanceMethods

        def details_to_strings_with_checklists(details, no_html = false, options = {})
          details_checklist, details_other = details.partition{ |x| x.prop_key == 'checklist' }
          if @issue.nil? || !User.current.allowed_to?(:view_checklists, @issue.try(:project), global: @issue.present?)
            return details_to_strings_without_checklists(details_other, no_html, options)
          end

          details_checklist.map do |detail|
            result = []
            diff = Hash.new([])

            if Checklist.old_format?(detail)
              result << "<b>#{l(:label_checklist_item)}</b> #{l(:label_checklist_changed_from)} #{detail.old_value} #{l(:label_checklist_changed_to)} #{detail.value}"
            else
              diff = JournalChecklistHistory.new(detail.old_value, detail.value).diff
            end

            checklist_item_label = lambda do |item|
              item[:is_section] ? l(:label_checklist_section) : l(:label_checklist_item)
            end

            if diff[:done].any?
              diff[:done].each do |item|
                result << "<b>#{ERB::Util.h l(:label_checklist_item)}</b> <input type='checkbox' class='checklist-checkbox' #{item.is_done ? 'checked' : '' } disabled> <i>#{ERB::Util.h item[:subject]}</i> #{ERB::Util.h l(:label_checklist_done)}"
              end
            end

            if diff[:undone].any?
              diff[:undone].each do |item|
                result << "<b>#{ERB::Util.h l(:label_checklist_item)}</b> <input type='checkbox' class='checklist-checkbox' #{item.is_done ? 'checked' : '' } disabled> <i>#{ERB::Util.h item[:subject]}</i> #{ERB::Util.h l(:label_checklist_undone)}"
              end
            end

            result = result.join('</li><li>').html_safe
            result = nil if result.blank?
            if result && no_html
              result = result.gsub /<\/li><li>/, "\n"
              result = result.gsub /<input type='checkbox' class='checklist-checkbox'[^c^>]*checked[^>]*>/, '[x]'
              result = result.gsub /<input type='checkbox' class='checklist-checkbox'[^c^>]*>/, '[ ]'
              result = result.gsub /<[^>]*>/, ''
              result = CGI.unescapeHTML(result)
            end
            result
          end.compact + details_to_strings_without_checklists(details_other, no_html, options)
        end
      end
    end
  end
end

unless IssuesHelper.included_modules.include?(RedmineChecklists::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineChecklists::Patches::IssuesHelperPatch)
end
