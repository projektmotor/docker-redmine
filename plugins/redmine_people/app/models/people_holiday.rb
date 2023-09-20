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

class PeopleHoliday < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  validates_presence_of :name, :start_date

  attr_accessor :notify

  after_create :send_notification

  scope :between, ->(from, to) { where('NOT (? > end_date OR start_date > ?)', from, to) }

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name',
                  'start_date',
                  'end_date',
                  'description',
                  'is_workday',
                  'notify'

  def due_date
    end_date || start_date
  end

  def due_date=(date)
    self.end_date = date
  end

  def self.next_holidays
    where('start_date > ? AND (is_workday = ? OR is_workday IS NULL)', Date.today, false).order('start_date ASC').first(5)
  end

  def notify?
    @notify.present?
  end

  def notify_all?
    @notify == 'all'
  end

  def notify_department
    Department.find(@notify) unless notify_all?
  end

  private

  def send_notification
    return unless notify?
    emails = Person.all_visible.emails if notify_all?
    emails ||= notify_department.people.emails
    Mailer.holiday_notification(User.current, self, emails).deliver if emails.present?
  end
end
