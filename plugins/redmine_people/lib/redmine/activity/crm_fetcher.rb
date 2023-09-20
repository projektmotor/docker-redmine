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

module Redmine
  module Activity
    # Class used to retrieve activity events
    class CrmFetcher < Fetcher

      # Returns an array of events for the given date range
      # sorted in reverse chronological order
      def events(from = nil, to = nil, options={})
        e = []
        @options[:limit] = options[:limit]

        @scope.each do |event_type|
          constantized_providers(event_type).each do |provider|
            e += find_events(provider, event_type, @user, from, to, @options)
          end
        end

        e.sort! {|a,b| b.event_datetime <=> a.event_datetime}

        if options[:limit]
          e = e.slice(0, options[:limit])
        end
        e
      end

      protected

      # Returns events of type event_type visible by user that occured between from and to
      # @param options[:author] - ActiveRecord::Relation, Array of Users, Integer, User
      def find_events(provider, event_type, user, from, to, options)
        provider_options = provider.activity_provider_options[event_type]

        raise "#{provider.name} can not provide #{event_type} events." if provider_options.nil?

        scope = (provider_options[:scope] || provider)
        scope = scope.call if scope.is_a?(Proc)

        if from && to
          scope = scope.where("#{provider_options[:timestamp]} BETWEEN ? AND ?", from, to)
        end

        if options[:author].present?
          return [] if provider_options[:author_key].nil?

          if options[:author].is_a?(ActiveRecord::Relation)
            author_ids = options[:author].map(&:id)
          elsif options[:author].is_a?(Array)
            author_ids = options[:author].map do |e|
              e.is_a?(User) ? e.id : nil
            end.compact
          elsif options[:author].is_a?(Integer)
            author_ids = options[:author]
          elsif options[:author].is_a?(User)
            author_ids = [options[:author].id]
          else
            raise ArgumentError.new("options[:author] is incorrect")
          end

          scope = scope.where("#{provider_options[:author_key]}" => author_ids)
        end

        if options[:limit]
          # id and creation time should be in same order in most cases
          scope = scope.reorder("#{provider::table_name}.id DESC").limit(options[:limit])
        end

        if provider_options.has_key?(:permission)
          scope = scope.where(Project.allowed_to_condition(user, provider_options[:permission] || :view_project, options))
        elsif provider.respond_to?(:visible)
          scope = scope.visible(user, options)
        else
          ActiveSupport::Deprecation.warn "acts_as_activity_provider with implicit :permission option is deprecated. Add a visible scope to the #{provider.name} model or use explicit :permission option."
          scope = scope.where(Project.allowed_to_condition(user, "view_#{provider.name.underscore.pluralize}".to_sym, options))
        end

        if ActiveRecord::VERSION::MAJOR >= 4
          scope.to_a
        else
          scope.all(provider_options[:find_options].dup)
        end
      end

      private

      def constantized_providers(event_type)
        Redmine::Activity.providers[event_type].map(&:constantize)
      end
    end
  end
end
