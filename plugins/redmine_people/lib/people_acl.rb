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

class PeopleAcl
  attr_accessor :principal_id, :permissions

  def initialize(principal_id, permissions)
    self.principal_id = principal_id.to_s
    self.permissions = permissions
  end

  def permissions=(perms)
    perms = perms.collect {|p| p.to_sym unless p.blank? && p.is_a?(String) && p.is_a?(Symbol) }.compact.uniq if perms
    @permissions = perms
  end


  def has_permission?(perm)
    return false unless perm.is_a?(String) || perm.is_a?(Symbol)
    !@permissions.nil? && @permissions.include?(perm.to_sym)
  end

  def principal
    Principal.find_by_id(self.principal_id)
  end

  def <<(perm)
    return false unless perm.is_a?(String) || perm.is_a?(Symbol)
    @permissions << perm.to_sym
  end

  def self.delete(principal_id)
    users_acls = Setting.plugin_redmine_people[:users_acl] || {}
    users_acls.delete(principal_id.to_s)
    Setting.plugin_redmine_people = Setting.plugin_redmine_people.merge(:users_acl => users_acls)
  end

  def self.create(principal_id, permissions)
    return false unless principal_id.blank? || Principal.find_by_id(principal_id)
    acl = self.new(principal_id, permissions)
    acl.save
  end

  def self.all
    return [] unless self.acls && self.acls.is_a?(Hash)
    self.acls.map do |acl|
      self.new(acl[0], acl[1]) if acl[0] && acl[1] && acl[1].is_a?(Array) && Principal.find_by_id(acl[0])
    end.compact || []
  end

  def self.find(principal_id)
    perms = self.acls && self.acls.is_a?(Hash) && self.acls[principal_id.to_s]
    self.new(principal_id.to_s, perms) if perms && perms.is_a?(Array)
  end

  def self.first
    self.all[0]
  end

  def self.allowed_to?(principal, permission)
    return false unless principal && principal.is_a?(Principal)
    if acl = self.find(principal.id)
      acl.has_permission?(permission)
    else
      false
    end
  end

  def save
    users_acls = Setting.plugin_redmine_people[:users_acl]
    users_acls = {} unless users_acls && users_acls.is_a?(Hash)
    users_acls.merge!(self.principal_id.to_s => self.permissions)
    Setting.plugin_redmine_people = Setting.plugin_redmine_people.merge(:users_acl => users_acls)
  end

  private

  def self.acls
    Setting.plugin_redmine_people[:users_acl]
  end
end
