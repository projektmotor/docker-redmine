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

class PeopleSettingsController < ApplicationController
  unloadable
  menu_item :people_settings

  layout 'admin'
  before_action :require_admin
  before_action :find_acl, :find_principals, :only => [:index]

  helper :departments
  helper :people
  helper :people_announcements

  def index
    @groups = Group.where(:type => 'Group').sort
    @departments = Department.all
  end

  def update
    settings = Setting.plugin_redmine_people
    settings = {} unless settings.is_a?(Hash)
    settings.merge!(params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash['settings'] : params['settings'])
    Setting.plugin_redmine_people = settings
    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'index', :tab => params[:tab]
  end

  def destroy
    PeopleAcl.delete(params[:id])
    find_acl
    find_principals
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index' }
      format.js
    end
  end

  def autocomplete_for_user
    find_principals
    render :layout => false
  end

  def create
    user_ids = params[:user_ids]
    acls = params[:acls]
    user_ids.each do |user_id|
      PeopleAcl.create(user_id, acls)
    end
    find_acl
    find_principals
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index', :tab => 'acl' }
      format.js
    end
  end

  private

  def find_acl
    @users_acl ||= PeopleAcl.all
  end

  def find_principals
    @principals = Principal.where(:status => [Principal::STATUS_ACTIVE, Principal::STATUS_ANONYMOUS]).order('type, login, lastname ASC')
    @principals = @principals.like(params[:q]) if params[:q]
    @principals = @principals.where('id NOT IN(?)', find_acl.map(&:principal_id)) if find_acl.any?
    @principals = @principals.limit(100)
  end
end
