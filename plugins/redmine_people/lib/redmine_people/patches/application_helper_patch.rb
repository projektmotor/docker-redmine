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
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :link_to_user_without_people, :link_to_user
          alias_method :link_to_user, :link_to_user_with_people

          alias_method :format_object_without_people, :format_object
          alias_method :format_object, :format_object_with_people

          unless RedminePeople.module_exists?(:AvatarsHelper)
            include AvatarsHelperPatch::InstanceMethods

            alias_method :avatar_without_people, :avatar
            alias_method :avatar, :avatar_with_people
          end
        end
      end

      module InstanceMethods
        def link_to_user_with_people(user, options = {})
          if user.is_a?(User)
            name = h(user.name(options[:format]))
            if user.active? && User.current.allowed_people_to?(:view_people, user)
              link_to name, :controller => 'people', :action => 'show', :id => user
            else
              name
            end
          else
            h(user.to_s)
          end
        end

        def format_object_with_people(object, html = true, &block)
          case object.class.name
          when 'Department'
            html ? format_department(object) : object.to_s
          when 'Person'
            html ? link_to_user(object) : object.to_s
          else
            format_object_without_people(object, html, &block)
          end
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedminePeople::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedminePeople::Patches::ApplicationHelperPatch)
end
