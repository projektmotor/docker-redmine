# encoding: utf-8
#
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
  module Charts
    module Helpers
      module ChartHelper
        def tooltip_dayoff_attributes(dayoff, options = {})
          options = { only_path: true }.merge(options)

          [{ name: l(:field_duration),          value: dayoff.duration },
           nil,
           { name: l(:label_people_person),     value: link_to(dayoff.user, person_path(dayoff.user), only_path: options[:only_path]) },
           { name: l(:label_people_leave_type), value: h(dayoff.leave_type.name) },
           { name: l(:field_status),            value: dayoff.is_approved? ? l(:field_approved) : l(:label_people_not_approved)},
           { name: l(:field_start_date),        value: format_date(dayoff.start_date) },
           { name: l(:field_end_date),          value: format_date(dayoff.due_date) },
           { name: l(:field_notes),             value: h(dayoff.notes) }]
        end

        def render_attributes(attributes, html = false)
          if html
            attributes.map { |attribute| render_attribute(attribute, html) + '<br />' }.join("\n").html_safe
          else
            attributes.map { |attribute| render_attribute(attribute, html) }.join("\n")
          end
        end

        def render_attribute(attribute, html = false)
          return '' unless attribute

          if html
            "<strong>#{attribute[:name]}</strong>: #{attribute[:value]}"
          else
            "* #{attribute[:name]}: #{attribute[:value]}"
          end
        end

        def dates_range_label(from, to, format = :short)
          if from == to
            I18n.l(from, format: format)
          else
            I18n.l(from, format: format) + ' - ' + I18n.l(to, format: format)
          end
        end
      end
    end
  end
end
