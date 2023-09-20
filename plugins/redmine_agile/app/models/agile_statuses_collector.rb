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

class AgileStatusesCollector
  def initialize(issue, options = {})
    @issue = issue
    @data = []
    fill_data
  end

  def data
    @data
  end

  def grouped_by(field)
    return unless field

    @data.group_by { |detail| detail.status_id } if field == 'status'
  end

  def object_for(field)
    return unless field
    return IssueStatus if field == 'status'
  end

  def issue_status_for(field, group_id)
    return IssueStatus.where(id: group_id).first if field == 'status'
  end

  def group_total_for(field, group_data)
    return unless field
    (group_data.map(&:duration).sum / 1.days).to_i if field == 'status'
  end

  private

  def fill_data
    assignee_id = initial_assignee_id
    @data << detail_object(initial_detail, initial_assignee_id, @issue.created_on)

    issue_details.each_with_index do |detail, idx|
      next if detail.prop_key != 'status_id'

      assignee_id = assignee_for(detail) || assignee_id
      @data << detail_object(detail, assignee_id, detail.journal.created_on)
    end

    @data.each_with_index do |detail, idx|
      detail.end_time = @data[idx + 1] ? @data[idx + 1].journal.created_on : Time.now
      detail.duration = detail.end_time - detail.start_time
    end
  end

  def detail_object(detail, assignee_id, start_time)
    OpenStruct.new(journal: detail.journal,
                   status_id: detail.value,
                   assigned_to_id: assignee_id,
                   start_time: start_time,
                   end_time: nil,
                   duration: nil)
  end

  def assignee_for(detail)
    detail.journal.details.detect { |detail| 'assigned_to_id' == detail.prop_key }.try(:value)
  end

  def issue_details
    return @issue_details if @issue_details

    @issue_details = @issue.journals.map(&:details).flatten.sort_by { |a| a.journal.created_on }
    @issue_details.unshift()
  end

  def first_status_detail
    issue_details.detect { |d| d.prop_key == 'status_id' }
  end

  def initial_assignee_id
    issue_details.detect { |detail| 'assigned_to_id' == detail.prop_key }.try(:old_value) || @issue.assigned_to_id
  end

  def initial_detail
    JournalDetail.new(property: 'attr',
                      prop_key: 'status_id',
                      value: first_status_detail.try(:old_value) || @issue.status.id,
                      journal: Journal.new(user: @issue.author, created_on: @issue.created_on))
  end
end
