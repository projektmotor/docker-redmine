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

class PeopleWorkExperience < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  belongs_to :person, :foreign_key => :user_id

  validates_presence_of :previous_company_name
  validates_presence_of :job_title

  scope :search, lambda { |company_name, job_title| where('previous_company_name LIKE ? AND job_title LIKE ?', "%#{company_name}%", "%#{job_title}%") }

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'previous_company_name',
                  'job_title',
                  'from_date',
                  'to_date',
                  'description',
                  'user_id'

  def self.editable?(person)
    edit_work_experience?(person) || edit_own_work_experience?(person)
  end

  def self.edit_work_experience?(person)
    allowed_to?(:edit_work_experience, person)
  end

  def self.edit_own_work_experience?(person)
    allowed_to?(:edit_own_work_experience, person)
  end

  def self.allowed_to?(action, person)
    User.current.allowed_people_to?(action, person)
  end
end
