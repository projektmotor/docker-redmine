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
    module ProjectsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :settings_without_agile, :settings
          alias_method :settings, :settings_with_agile
        end
      end

      module InstanceMethods
        def settings_with_agile
          settings_without_agile

          @sprint_status = params[:sprint_status] || ''
          @project_sprints = @project.agile_sprints.status(@sprint_status).sorted
        end
      end
    end
  end
end

unless ProjectsController.included_modules.include?(RedmineAgile::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, RedmineAgile::Patches::ProjectsControllerPatch)
end
