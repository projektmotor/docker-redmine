# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

module RedminePeople
  module Patches
    module AttachmentsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :destroy_without_people, :destroy
          alias_method :destroy, :destroy_with_people
        end
      end

      module InstanceMethods
        def destroy_with_people
          @project = Project.first
          request.headers['Referer'] = person_path(@attachment.container) if @attachment.container_type == 'Principal'
          destroy_without_people
        end
      end
    end
  end
end

unless AttachmentsController.included_modules.include?(RedminePeople::Patches::AttachmentsControllerPatch)
  AttachmentsController.send(:include, RedminePeople::Patches::AttachmentsControllerPatch)
end
