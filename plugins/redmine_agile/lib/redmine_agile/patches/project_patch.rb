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
    module ProjectPatch

      def self.included(base)
        base.class_eval do
          base.send(:include, InstanceMethods)
          acts_as_colored
          safe_attributes 'agile_color_attributes',
            if: lambda { |project, user| user.allowed_to?(:edit_project, project) && user.allowed_to?(:view_agile_queries, project) && RedmineAgile.use_colors? }
          has_many :agile_sprints
        end
      end

      module InstanceMethods
        def shared_agile_sprints
          @shared_agile_sprints ||=
          if new_record?
            AgileSprint.
              joins(:project).
              preload(:project).
              where("#{Project.table_name}.status <> ? AND #{AgileSprint.table_name}.sharing = ?", Project::STATUS_ARCHIVED, AgileSprint.sharings[:system])
          else
            r = root? ? self : root
            AgileSprint.
              joins(:project).
              preload(:project).
              where("#{Project.table_name}.id = #{id}" +
                    " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND (" +
                      " #{AgileSprint.table_name}.sharing = #{AgileSprint.sharings[:system]}" +
                      " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{AgileSprint.table_name}.sharing = #{AgileSprint.sharings[:tree]})" +
                      " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{AgileSprint.table_name}.sharing IN (#{AgileSprint.sharings[:hierarchy]}, #{AgileSprint.sharings[:descendants]}))" +
                      " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{AgileSprint.table_name}.sharing = #{AgileSprint.sharings[:hierarchy]})" +
                    "))")
          end
        end

        def agile_sprints_any?
          agile_sprints.any? || shared_agile_sprints.any?
        end

        def active_sprint
          agile_sprints.active.first || shared_agile_sprints.active.first
        end
      end
    end

  end
end

unless Project.included_modules.include?(RedmineAgile::Patches::ProjectPatch)
  Project.send(:include, RedmineAgile::Patches::ProjectPatch)
end
