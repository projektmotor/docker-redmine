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

requires_redmine_crm :version_or_higher => '0.0.59' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

PEOPLE_VERSION_NUMBER = '1.6.3'
PEOPLE_VERSION_TYPE = "Light version"

QUOTED_TRUE = (ActiveRecord::Base.connection rescue false) && ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')
QUOTED_FALSE = (ActiveRecord::Base.connection rescue false) && ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')

Redmine::Plugin.register :redmine_people do
  name "Redmine People plugin (#{PEOPLE_VERSION_TYPE})"
  author 'RedmineUP'
  description 'This is a plugin for managing Redmine users'
  version PEOPLE_VERSION_NUMBER
  url 'http://redmineup.com/pages/plugins/people'
  author_url 'mailto:support@redmineup.com'

  requires_redmine :version_or_higher => '3.0'

  settings default: {
    users_acl: {},
    visibility: '',
    hide_age: '0',
    edit_own_data: '1',
    default_group: '',
    'workday_length' => 8
  }

  menu :top_menu, :people, { :controller => 'people', :action => 'index', :project_id => nil }, :caption => :label_people, :if => Proc.new {
    User.current.allowed_people_to?(:view_people)
  }

  menu :admin_menu, :people, { :controller => 'people_settings', :action => 'index' }, :caption => :label_people, :html => { :class => 'icon' }
end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end
require File.dirname(__FILE__) + '/lib/redmine_people'

RedmineCrm::Settings.initialize_gem_settings
RedmineCrm::Currency.add_admin_money_menu
