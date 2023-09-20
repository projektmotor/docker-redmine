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

class AgileColor < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  COLOR_GROUPS = {
    :issue => 'issue',
    :priority => 'priority',
    :tracker => 'tracker',
    :spent_time => 'spent_time',
    :user => 'user',
    :project => 'project'
  }

  AGILE_COLORS = {
    :green  => 'green',
    :blue => 'blue',
    :turquoise  => 'turquoise',
    :light_green  => 'lightgreen',
    :yellow => 'yellow',
    :orange => 'orange',
    :red  => 'red',
    :purple => 'purple',
    :gray => 'gray'
  }

  belongs_to :container, :polymorphic => true

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'color'

  def self.for_user(user_name)
    return '#ffffff'.html_safe if !user_name
    "##{"%06x" % (user_name.unpack('H*').first.hex % 0xffffff)}".html_safe
  end

  def self.for_spent_time(est_time = nil, spent_time = nil)
    return AGILE_COLORS[:gray] if !est_time || !spent_time || est_time.to_f.zero? || (spent_time.to_f.zero? && est_time.to_f.zero?)
    percent = ((spent_time / est_time.to_f) * 100).to_i
    if percent <= 80
      return AGILE_COLORS[:green]
    elsif percent > 80 && (spent_time < est_time)
      return AGILE_COLORS[:yellow]
    elsif (spent_time >= est_time) && (spent_time < est_time * 2)
      return AGILE_COLORS[:red]
    elsif spent_time >= est_time * 2
      return AGILE_COLORS[:purple]
    end
  end
end
