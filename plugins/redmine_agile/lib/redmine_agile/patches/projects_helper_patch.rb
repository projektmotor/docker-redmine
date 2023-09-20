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

require_dependency 'queries_helper'

module RedmineAgile
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :project_settings_tabs_without_agile, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_agile
        end
      end

      module InstanceMethods
        def project_settings_tabs_with_agile
          tabs = project_settings_tabs_without_agile

          tabs.push(:name => 'agile_sprints',
                    :action => :manage_sprints,
                    :partial => 'projects/project_agile_sprints',
                    :label => :label_agile_sprint_plural) if User.current.allowed_to?(:manage_sprints, @project)
          tabs
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineAgile::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineAgile::Patches::ProjectsHelperPatch)
end
