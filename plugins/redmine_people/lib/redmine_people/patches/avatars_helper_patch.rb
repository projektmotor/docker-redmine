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
    module AvatarsHelperPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          alias_method :avatar_without_people, :avatar
          alias_method :avatar, :avatar_with_people
        end
      end

      module InstanceMethods
        def avatar_with_people(user, options = {})
          options[:width] = options[:size] || GravatarHelper::DEFAULT_OPTIONS[:size] unless options[:width]
          options[:height] = options[:size] || GravatarHelper::DEFAULT_OPTIONS[:size] unless options[:height]
          if ActiveRecord::VERSION::MAJOR >= 4
            options[:size] = "#{options[:width]}x#{options[:height]}"
            options.except!(:width, :height)
          end
          if user.blank? || user.is_a?(String) || (user.is_a?(User) && user.anonymous?)
            return avatar_without_people(user, options)
          end
          if user.is_a?(User) && (avatar = user.avatar)
            avatar_url = url_for protocol: Setting.protocol, only_path: options.fetch(:only_path, false), controller: 'people', action: 'avatar', id: avatar, size: options[:size]
            image_tag(avatar_url, options.merge(class: "gravatar #{'without-margin' if !Setting.gravatar_enabled? && Redmine::VERSION.to_s >= '4'}"))
          elsif user.respond_to?(:twitter) && !user.twitter.blank?
            image_tag("https://twitter.com/#{user.twitter}/profile_image?size=original", options.merge(:class => 'gravatar'))
          elsif !Setting.gravatar_enabled?
            image_tag('person.png', options.merge(:plugin => 'redmine_people', :class => "gravatar #{'without-margin' if Redmine::VERSION.to_s >= '4'}"))
          else
            avatar_without_people(user, options)
          end
        end
      end
    end
  end
end

if RedminePeople.module_exists?(:AvatarsHelper)
  unless AvatarsHelper.included_modules.include?(RedminePeople::Patches::AvatarsHelperPatch)
    AvatarsHelper.send(:include, RedminePeople::Patches::AvatarsHelperPatch)
  end
end
