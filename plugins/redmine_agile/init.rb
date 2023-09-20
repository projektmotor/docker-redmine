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

requires_redmine_crm version_or_higher: '0.0.56' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

require 'redmine'

AGILE_VERSION_NUMBER = '1.6.5'
AGILE_VERSION_TYPE = 'PRO version'

if ActiveRecord::VERSION::MAJOR >= 4 && !defined?(FCSV)
  require 'csv'
  FCSV = CSV
end

Redmine::Plugin.register :redmine_agile do
  name "Redmine Agile plugin (#{AGILE_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Scrum and Agile project management plugin for redmine'
  version AGILE_VERSION_NUMBER
  url 'http://redmineup.com/pages/plugins/agile'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '3.0'

  settings default: { 'default_columns' => %w(tracker assigned_to) },
           partial: 'settings/agile/agile'

  menu :application_menu, :agile,
       { controller: 'agile_boards', action: 'index' },
       caption: :label_agile,
       if: Proc.new { User.current.allowed_to?(:view_agile_queries, nil, global: true) }
  menu :project_menu, :agile_backlog, { controller: 'agile_versions', action: 'index' }, caption: :label_agile_board_backlog,
                                                                                         after: :gantt,
                                                                                         param: :project_id,
       if: Proc.new { User.current.allowed_to?(:view_backlog, nil, global: true) }
  menu :project_menu, :agile, { controller: 'agile_boards', action: 'index' }, caption: :label_agile,
                                                                               after: :gantt,
                                                                               param: :project_id

  menu :admin_menu, :agile, { controller: 'settings', action: 'plugin', id: 'redmine_agile' }, caption: :label_agile, html: { class: 'icon' }

  project_module :agile do
    permission :manage_public_agile_queries, { agile_queries: [:new, :create, :edit, :update, :destroy] }, require: :member
    permission :add_agile_queries, { agile_queries: [:new, :create, :edit, :update, :destroy] }, require: :loggedin
    permission :view_agile_queries, { agile_boards: [:index,
                                                     :update,
                                                     :create_issue,
                                                     :issue_tooltip,
                                                     :inline_comment,
                                                     :agile_data,
                                                     :backlog_load_more,
                                                     :backlog_autocomplete],
                                      agile_queries: :index }, read: true
    permission :view_agile_charts, { agile_charts: [:show, :render_chart, :select_version_chart] }, read: true
    permission :manage_sprints, {
      agile_sprints: [:index, :new, :create, :edit, :update, :destroy],
      agile_versions: [:sprints]
    }
  end
  project_module :agile_backlog do
    permission :view_backlog, { agile_versions: [:index, :update] }
    permission :manage_backlog, { agile_boards: [:update, :issue_tooltip, :inline_comment, :backlog_load_more, :backlog_autocomplete] }
  end
end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end
require File.dirname(__FILE__) + '/lib/redmine_agile'
