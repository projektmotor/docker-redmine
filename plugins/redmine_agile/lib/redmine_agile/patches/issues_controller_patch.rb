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
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          helper :agile_sprints
          include AgileSprintsHelper
        end
      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineAgile::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineAgile::Patches::IssuesControllerPatch)
end
