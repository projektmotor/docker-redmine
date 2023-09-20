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

class Person < User
  unloadable
  include Redmine::SafeAttributes
  include Redmine::Pagination

  self.inheritance_column = :_type_disabled

  has_one :information, :class_name => 'PeopleInformation', :foreign_key => :user_id, :dependent => :destroy

  delegate :phone, :address, :skype, :birthday, :job_title, :company, :middlename, :gender, :twitter,
           :facebook, :linkedin, :department_id, :background, :appearance_date, :is_system, :manager_id,
           :to => :information, :allow_nil => true

  acts_as_customizable

  accepts_nested_attributes_for :information, :allow_destroy => true, :update_only => true, :reject_if => proc { |attributes| PeopleInformation.reject_information(attributes) }

  has_one :department, :through => :information

  has_one :manager, :through => :information

  has_many :time_entries, foreign_key: :user_id, dependent: :destroy

  rcrm_acts_as_taggable

  scope :in_department, lambda { |department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id = ?) AND (#{Person.table_name}.type = 'User')", department_id)
  }
  scope :not_in_department, lambda { |department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id != ?) OR (#{PeopleInformation.table_name}.department_id IS NULL)", department_id)
  }

  scope :seach_by_name, lambda { |search| eager_load(ActiveRecord::VERSION::MAJOR >= 4 ? [:information, :email_address] : [:information])
                                          .where("(LOWER(#{Person.table_name}.firstname) LIKE :search OR
                                                   LOWER(#{Person.table_name}.lastname) LIKE :search OR
                                                   LOWER(#{PeopleInformation.table_name}.middlename) LIKE :search OR
                                                   #{concated_names_sql}
                                                   LOWER(#{Person.table_name}.login) LIKE :search OR
                                                   LOWER(#{(ActiveRecord::VERSION::MAJOR >= 4) ? (EmailAddress.table_name + '.address') : (Person.table_name + '.mail')}) LIKE :search)",
                                                   :search => search.downcase + '%') }

  scope :managers, lambda { joins("INNER JOIN #{PeopleInformation.table_name} ON #{Person.table_name}.id = #{PeopleInformation.table_name}.manager_id").uniq }

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'custom_field_values',
                  'custom_fields',
                  'information_attributes',
                  'auth_source_id',
    :if => lambda { |person, user| (person.new_record? && user.allowed_people_to?(:add_people, person)) || user.allowed_people_to?(:edit_people, person) }

  safe_attributes 'status',
    :if => lambda { |person, user| user.allowed_people_to?(:edit_people, person) && person.id != user.id && !person.admin }

  safe_attributes 'tag_list',
    :if => lambda { |person, user| user.allowed_people_to?(:manage_tags, person) }

  def self.genders
    [[l(:label_people_male), 0], [l(:label_people_female), 1]]
  end

  def type
    'User'
  end

  def email
    mail
  end

  def project
    nil
  end

  def subordinates
    scope = Person.eager_load(:information).where("#{PeopleInformation.table_name}.manager_id" => id.to_i)
    scope = scope.visible if Person.respond_to?(:visible)
    scope
  end

  def available_managers
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User').logged
    scope = scope.visible if Person.respond_to?(:visible)

    if id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i)
                   .where("#{Person.table_name}.id <> ?", id.to_i)
    end
    scope
  end

  def available_subordinates
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User').logged
    scope = scope.visible if Person.respond_to?(:visible)

    if id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i)
                   .where("#{Person.table_name}.id <> ?", id.to_i)
      scope = scope.where("#{Person.table_name}.id != ?", manager_id.to_i) if manager_id.present?
    end
    scope
  end

  def phones
    @phones || phone ? phone.split(/, */) : []
  end

  def next_birthday
    return if birthday.blank?
    year = Date.today.year
    mmdd = birthday.strftime('%m%d')
    year += 1 if mmdd < Date.today.strftime('%m%d')
    mmdd = '0301' if mmdd == '0229' && !Date.parse("#{year}0101").leap?
    Date.parse("#{year}#{mmdd}")
  end

  def age
    return nil if birthday.blank?
    now = Time.now
    now.year - birthday.year - (birthday.to_time.change(:year => now.year) > now ? 1 : 0)
  end

  def editable_by?(_usr, _prj = nil)
    true
    # usr && (usr.allowed_to?(:edit_people, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def visible?(user = User.current)
    if Redmine::VERSION.to_s >= '3.0'
      principal = Principal.visible(user).where(:id => id).first
      return principal.present?
    end
    true
  end

  def attachments_visible?(_user = User.current)
    true
  end

  def available_custom_fields
    CustomField.where("type = 'UserCustomField'").sorted.to_a
  end

  def remove_subordinate(subordinate_id)
    subordinate = Person.find(subordinate_id.to_i)
    return false if subordinate.blank?

    subordinate.safe_attributes = { 'information_attributes' => { 'manager_id' => nil } }
    subordinate.save
  end

  def all_visible_attachments
    attachments.select { |a| a != avatar } if visible?
  end

  def all_visible_memberships
    memberships.where(Project.visible_condition(User.current)) if visible?
  end

  def all_visible_events
    Redmine::Activity::Fetcher.new(User.current, :author => self).events(nil, nil, :limit => 10).group_by(&:event_date) if visible?
  end

  def all_visible_subordinates(page, limit)
    if visible?
      # limit = per_page_option
      subordinates_count = subordinates.count

      if Redmine::VERSION.to_s > '2.5'
        subordinate_pages = Paginator.new(subordinates_count, limit, page)
        offset = subordinate_pages.offset
      else
        subordinate_pages = Paginator.new(self, subordinates_count, limit, page)
        offset = subordinate_pages.current.offset
      end

      subordinates.limit(limit).offset(offset)
    end
  end

  class << self
    def emails
      (Redmine::VERSION.to_s >= '3.0' ? joins(:email_address).pluck("LOWER(#{EmailAddress.table_name}.address)") : pluck(:mail)).delete_if { |v| v.blank? }.uniq
    end

    def next_birthdays(limit = 10)
      Person.eager_load(:information).active.where("#{PeopleInformation.table_name}.birthday IS NOT NULL").sort_by(&:next_birthday).first(limit)
    end

    def tomorrow_birthdays
      Person.next_birthdays.select { |p| p.next_birthday == Date.today + 1 }
    end

    def today_birthdays
      Person.next_birthdays.select { |p| p.next_birthday == Date.today }
    end

    def week_birthdays
      Person.next_birthdays.select { |p| p.next_birthday <= Date.today.end_of_week && p.next_birthday > Date.tomorrow }
    end

    def all_visible
      scope = Person.active
      scope = scope.visible if Redmine::VERSION.to_s >= '3.0'
      scope
    end

    def all_visible_next_birthdays
      next_birthdays = Person.all_visible
      next_birthdays.next_birthdays
    end

    def all_visible_new_people
      new_people = Person.all_visible
      new_people.eager_load(:information)
                .where("#{PeopleInformation.table_name}.appearance_date IS NOT NULL")
                .where("#{PeopleInformation.table_name}.appearance_date > ?", Date.today - 30.days)
                .order("#{PeopleInformation.table_name}.appearance_date desc")
                .first(5)
    end

    def concated_names_sql
      case ActiveRecord::Base.connection.class.name
      when /Mysql/
        return 'LOWER(CONCAT(firstname, lastname)) LIKE :search OR LOWER(CONCAT(lastname, firstname)) LIKE :search OR'
      when /SQLServer/
        return 'LOWER(firstname + lastname) LIKE :search OR LOWER(lastname + firstname) LIKE :search OR'
      end
      'LOWER(firstname || lastname) LIKE :search OR LOWER(lastname || firstname) LIKE :search OR'
    end
  end
end
