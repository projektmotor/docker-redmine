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
    module IssueDropPatch

      def self.included(base)
        base.class_eval do
          base.send(:include, InstanceMethods)
        end
      end

      module InstanceMethods
        def time_in_statuses
          statuses_data = AgileStatusesCollector.new(@issue).grouped_by('status')
          statuses = Hash[IssueStatus.where(id: statuses_data.keys).map { |s| [s.id.to_s, s.name] }]
          Hash[statuses_data.map { |sid, data| [statuses[sid], (data.map(&:duration).sum / 1.days).round] }]
        end
      end
    end

  end
end

unless RedmineCrm::Liquid::IssueDrop.included_modules.include?(RedmineAgile::Patches::IssueDropPatch)
  RedmineCrm::Liquid::IssueDrop.send(:include, RedmineAgile::Patches::IssueDropPatch)
end
