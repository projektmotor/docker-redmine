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

require_dependency 'query'

module RedminePeople
  module Patches
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method :add_filter_without_people, :add_filter
          alias_method :add_filter, :add_filter_with_people
        end
      end

      module InstanceMethods
        def add_filter_with_people(field, operator, values = nil)
          add_filter_without_people(field, operator, values)

          if available_filters[field] && %w(people).include?(available_filters[field][:type])
            filter_options = available_filters[field]
            # Method :contact_query_values should be defined in query class for model
            filter_options[:values] = contact_query_values(values) if respond_to?(:contact_query_values)
            return if filter_options[:values].present?
            filter_options[:values] = Person.managers.where(:id => values).
                                                      to_a.sort! { |x, y| x.name <=> y.name }.
                                                      collect { |m| [m.name.html_safe, m.id.to_s] }
          end
          if available_filters[field] && available_filters[field][:type] == :people_tags
            available_filters[field][:values] = people_tags_values(values) if respond_to?(:people_tags_values)
          end
          true
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedminePeople::Patches::QueryPatch)
  Query.send(:include, RedminePeople::Patches::QueryPatch)
end
