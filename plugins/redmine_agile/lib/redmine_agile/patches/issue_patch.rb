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
  module Patches

    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_one :agile_data, :dependent => :destroy
          has_one :agile_sprint, through: :agile_data
          delegate :position, :to => :agile_data, :allow_nil => true
          scope :sorted_by_rank, lambda { eager_load(:agile_data).
                                          order(Arel.sql("COALESCE(#{AgileData.table_name}.position, 999999  )")) }
          alias_method :css_classes_without_agile, :css_classes
          alias_method :css_classes, :css_classes_with_agile

          acts_as_colored

          safe_attributes 'agile_color_attributes',
            :if => lambda { |issue, user| user.allowed_to?(:edit_issues, issue.project) && user.allowed_to?(:view_agile_queries, issue.project) && RedmineAgile.issue_colors? }
          safe_attributes 'agile_data_attributes', :if => lambda { |issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
          accepts_nested_attributes_for :agile_data, :allow_destroy => true

          alias_method :agile_data_without_default, :agile_data
          alias_method :agile_data, :agile_data_with_default
          alias_method :'safe_attributes=_without_agile', :'safe_attributes='
          alias_method :'safe_attributes=', :'safe_attributes=_with_agile'

          alias_method :copy_from_without_agile, :copy_from
          alias_method :copy_from, :copy_from_with_agile
        end
      end

      module InstanceMethods
        def agile_data_with_default
          agile_data_without_default || build_agile_data
        end

        def day_in_state
          change_time = journals.joins(:details).where(:journals => { :journalized_id => id, :journalized_type => 'Issue' },
                                                       :journal_details => { :prop_key => 'status_id' }).order('created_on DESC').first
          change_time.created_on
        rescue
          created_on
        end

        def last_comment
          journals.where("notes <> ''").order("#{Journal.table_name}.id ASC").last
        end

        def story_points
          @story_points ||= agile_data.story_points
        end
        def css_classes_with_agile(user = User.current)
          s = if Redmine::VERSION.to_s < '2.4'
                css_classes_without_agile
              else
                css_classes_without_agile(user)
              end
          s << " #{RedmineAgile.color_prefix}-#{color}" if RedmineAgile.issue_colors? && color
          s
        end

        define_method 'safe_attributes=_with_agile' do |attrs, user=User.current|
          if attrs && attrs[:agile_data_attributes].present?
            attrs[:agile_data_attributes][:id] = agile_data.try(:id)
            attrs[:agile_data_attributes].delete(:agile_sprint_id) unless User.current.allowed_to?(:manage_sprints, project)
          end
          send('safe_attributes=_without_agile', attrs, user)
        end

        def copy_from_with_agile(arg, options={})
          original_issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          copied_issue = copy_from_without_agile(original_issue, options)
          copied_issue.build_agile_data(story_points: original_issue.agile_data[:story_points],
                                        agile_sprint_id: original_issue.agile_data[:agile_sprint_id])
          copied_issue
        end

        def sub_issues
          descendants
        end
      end
    end

  end
end

unless Issue.included_modules.include?(RedmineAgile::Patches::IssuePatch)
  Issue.send(:include, RedmineAgile::Patches::IssuePatch)
end
