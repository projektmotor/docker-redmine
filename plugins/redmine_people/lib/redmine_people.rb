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
  def self.available_permissions
    permissions = [
      :edit_people, :view_people, :add_people, :delete_people, :manage_departments,
      :manage_tags, :manage_public_people_queries, :edit_subordinates, :edit_announcement,
      :edit_work_experience, :edit_own_work_experience, :manage_calendar, :view_reports
    ]
    permissions
  end

  def self.settings() Setting[:plugin_redmine_people] end

  def self.users_acl() Setting.plugin_redmine_people[:users_acl] || {} end

  def self.default_list_style
    return 'list_excerpt'
  end

  def self.organization_name
    settings['organization_name']
  end

  def self.url_exists?(url)
    require_dependency 'open-uri'
    begin
      open(url)
      true
    rescue
      false
    end
  end

  def self.hide_age?
    Setting.plugin_redmine_people["hide_age"].to_i > 0
  end

  # TODO: Not used anywhere. Perhaps need to remove.
  def self.contacts_plugin_with_select2?
    Redmine::Plugin.installed?(:redmine_contacts) && Redmine::Plugin.find(:redmine_contacts).version >= '4.0.8'
  end

  def self.module_exists?(name)
    const_defined?(name) && const_get(name).instance_of?(Module)
  end
end

REDMINE_PEOPLE_REQUIRED_FILES = [
  'people_acl',
  'redmine/activity/crm_fetcher',
  'redmine_people/patches/action_controller_patch',
  'redmine_people/helpers/redmine_people',
  'acts_as_attachable_global/init',
  'redmine_people/patches/application_controller_patch',
  'redmine_people/patches/user_patch',
  'redmine_people/patches/application_helper_patch',
  'redmine_people/patches/avatars_helper_patch',
  'redmine_people/patches/users_controller_patch',
  'redmine_people/patches/my_controller_patch',
  'redmine_people/patches/calendar_patch',
  'redmine_people/patches/query_patch',
  'redmine_people/patches/mailer_patch',
  'redmine_people/patches/attachments_controller_patch',
  'redmine_people/hooks/views_layouts_hook',
  'redmine_people/hooks/views_my_account_hook',
]

REDMINE_PEOPLE_REQUIRED_FILES << 'redmine_people/patches/query_filter_patch' if Redmine::VERSION.to_s >= '3.4'
REDMINE_PEOPLE_REQUIRED_FILES << 'redmine_people/patches/attachments_helper_patch' if Redmine::VERSION.to_s >= '5.0'

base_url = File.dirname(__FILE__)
REDMINE_PEOPLE_REQUIRED_FILES.each { |file| require(base_url + '/' + file) }
