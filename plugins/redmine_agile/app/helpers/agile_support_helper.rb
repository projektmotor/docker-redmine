# encoding: utf-8
#
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

module AgileSupportHelper
  include ActionView::Helpers::DateHelper

  # Returns a h2 tag and sets the html title with the given arguments
  def title(*args)
    strings = args.map do |arg|
      if arg.is_a?(Array) && arg.size >= 2
        link_to(*arg)
      else
        h(arg.to_s)
      end
    end
    html_title args.reverse.map {|s| (s.is_a?(Array) ? s.first : s).to_s}
    content_tag('h2', strings.join(' &#187; ').html_safe)
  end

  def event_duration(event, next_event)
    end_time = next_event ? next_event.journal.created_on : Time.now
    distance_of_time_in_words(end_time, event.journal.created_on).html_safe
  end

  def issue_statuses_to_csv(collector)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = 'utf-8'
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      headers = [ "#",
                  l(:field_created_on, locale: :en),
                  l(:field_status, locale: :en),
                  l(:field_duration, locale: :en),
                  l(:field_author, locale: :en),
                  l(:field_assigned_to, locale: :en)
                  ]
      csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }

      collector.data.each_with_index do |data, index|
        issue_status = IssueStatus.where(id: data.status_id).first
        fields = [index + 1,
                  format_time(data.journal.created_on),
                  issue_status.name,
                  distance_of_time_in_words(data.end_time, data.start_time),
                  data.journal.user.name,
                  Principal.where(id: data.assigned_to_id).first.try(:name)
                  ]
        csv << fields.collect { |c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      end
    end
    export
  end
end
