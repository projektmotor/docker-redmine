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
    module ApplicationControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
        end
      end

      module InstanceMethods
        private

        def set_person
          @person = Person.find(params[:person_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedminePeople::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedminePeople::Patches::ApplicationControllerPatch)
end
