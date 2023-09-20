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

require_dependency 'application_helper'

module RedminePeople
  module Patches
    module AttachmentsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :container_attachments_download_path_without_people, :container_attachments_download_path
          alias_method :container_attachments_download_path, :container_attachments_download_path_with_people
        end
      end

      module InstanceMethods
        def container_attachments_download_path_with_people(container)
          return departments_attachments_download_path container.class.name.underscore.pluralize, container.id if container.is_a?(Department)

          container_attachments_download_path_without_people(container)
        end
      end
    end
  end
end

unless AttachmentsHelper.included_modules.include?(RedminePeople::Patches::AttachmentsHelperPatch)
  AttachmentsHelper.send(:include, RedminePeople::Patches::AttachmentsHelperPatch)
end
