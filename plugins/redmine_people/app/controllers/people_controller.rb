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

class PeopleController < ApplicationController
  Mime::Type.register 'text/x-vcard', :vcf

  before_action :find_person, :only => [:show, :edit, :update, :destroy, :edit_membership, :destroy_membership,
                                        :destroy_avatar, :load_tab, :remove_subordinate]
  before_action :find_managers, :only => [:manager, :autocomplete_for_manager, :add_manager]
  before_action :authorize_people, :except => [:avatar, :context_menu, :bulk_edit, :bulk_update, :autocomplete_tags,
                                               :manager, :autocomplete_for_manager, :add_manager, :autocomplete_for_person]

  before_action :bulk_find_people, :only => [:context_menu, :bulk_edit, :bulk_update]
  before_action :limit_per_page_option, :only => [:load_tab, :show, :remove_subordinate]
  before_action :get_data_for_tab, only: [:load_tab, :show]

  include PeopleHelper
  helper :queries
  helper :departments
  helper :context_menus
  helper :custom_fields
  helper :sort
  include SortHelper
  helper :attachments

  def index
    retrieve_people_query
    sort_init(@query.sort_criteria.empty? ? [['lastname', 'asc'], ['firstname', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf', 'xls', 'vcf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @people_count = @query.object_count

      if Redmine::VERSION.to_s > '2.5'
        @people_pages = Paginator.new(@people_count, @limit, params[:page])
        @offset = @people_pages.offset
      else
        @people_pages = Paginator.new(self, @people_count, @limit, params[:page])
        @offset = @people_pages.current.offset
      end

      @people_count_by_group = @query.object_count_by_group
      @people = @query.results_scope(
        preload: [:tags, :avatar],
        search: params[:search],
        order: sort_clause,
        limit: @limit,
        offset: @offset
      )

      respond_to do |format|
        format.html {render partial: people_list_style, layout: false if request.xhr?}
      end

    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def edit
    @auth_sources = AuthSource.all
    @departments = Department.all.sort
    @membership ||= Member.new
    @person.build_information unless @person.information
  end

  def new
    @person = Person.new(language: Setting.default_language, mail_notification: Setting.default_notification_option)
    @person.build_information
    @person.safe_attributes = { 'information_attributes' => { 'department_id' => params[:department_id], 'manager_id' => params[:manager_id] } }

    @auth_sources = AuthSource.all
    @departments = Department.all.sort
  end

  def update
    (render_403; return false) unless @person.editable_by?(User.current)
    @person.safe_attributes = params[:person]
    if @person.save
      attachments = Attachment.attach_files(@person, params[:attachments])
      render_attachment_warning_if_needed(@person)
      flash[:notice] = l(:notice_successful_update)
      attach_avatar
      respond_to do |format|
        format.html { redirect_to action: 'show', id: @person, tab: params[:tab] }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit', status: 400 }
        format.api  { render_validation_errors(@person) }
      end
    end
  end

  def create
    @person  = Person.new(language: Setting.default_language, mail_notification: Setting.default_notification_option)
    @person.safe_attributes = params[:person]
    @person.admin = false
    @person.login = params[:person][:login]
    @person.password, @person.password_confirmation = params[:person][:password], params[:person][:password_confirmation] unless @person.auth_source_id
    @person.type = 'User'
    if @person.save
      @person.pref.attributes = params[:pref] if params[:pref]
      @person.pref[:no_self_notified] = (params[:no_self_notified] == '1')
      @person.pref.save
      @person.notified_project_ids = (@person.mail_notification == 'selected' ? params[:notified_project_ids] : [])
      @person.group_ids = params[:person][:group_ids] if groups_present?
      attach_avatar
      Mailer.account_information(@person, params[:person][:password]).deliver if params[:send_information]

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create, id: view_context.link_to(@person.login, person_path(@person)))
          redirect_to(params[:continue] ?
            {controller: 'people', action: 'new'} :
            {controller: 'people', action: 'show', id: @person}
          )
        }
        format.api  { render action: 'show', status: :created, location: person_url(@person) }
      end
    else
      @auth_sources = AuthSource.all
      # Clear password input
      @person.password = @person.password_confirmation = nil

      respond_to do |format|
        format.html { render action: 'new' }
        format.api  { render_validation_errors(@person) }
      end
    end
  end

  def destroy
    @person.destroy
    respond_to do |format|
      format.html { redirect_back_or_default(people_path) }
    end
  end

  def avatar
    attachment = Attachment.find(params[:id])
    if attachment.readable? && attachment.thumbnailable?
      # images are sent inline
      if (defined?(RedmineContacts::Thumbnail) == 'constant') && Redmine::Thumbnail.convert_available?
        target = File.join(attachment.class.thumbnails_storage_path, "#{attachment.id}_#{attachment.digest}_#{params[:size]}.thumb")
        thumbnail = RedmineContacts::Thumbnail.generate(attachment.diskfile, target, params[:size])
      elsif Redmine::Thumbnail.convert_available?
        thumbnail = attachment.thumbnail(size: params[:size])
      else
        thumbnail = attachment.diskfile
      end

      if stale?(etag: attachment.digest)
        send_file thumbnail, filename: (request.env['HTTP_USER_AGENT'] =~ %r{MSIE} ? ERB::Util.url_encode(attachment.filename) : attachment.filename),
                                        type: detect_content_type(attachment),
                                        disposition: 'inline'
      end

    else
      # No thumbnail for the attachment or thumbnail could not be created
      render nothing: true, status: 404
    end
  rescue ActiveRecord::RecordNotFound
    render nothing: true, status: 404
  end

  def context_menu
    @person = @people.first if @people.size == 1
    @can = { edit: bulk_edit_access? }
    return render nothing: true, status: 200 unless @person
    # <BITNAMI/> return render nothing: true, status: 200 unless @person
    render layout: false
  end

  def autocomplete_tags
    if request.xhr?
      @name = params[:q].to_s
      @tags = Person.all_tag_counts(conditions: ["#{RedmineCrm::Tag.table_name}.name LIKE ?", "%#{@name}%"], limit: 10)
      render layout: false, partial: 'person_tag_list', status: 200
    else
      render_404
    end
  end

  def load_tab
  end

  def manager
    @managers = @managers.limit(10)
  end

  def autocomplete_for_manager
    @managers = @managers.like(params[:q]).limit(100).preload(Redmine::VERSION.to_s >= '3.0' ? [:avatar, :email_address] : [:avatar]).to_a
  end

  def add_manager
  end

  def destroy_avatar
    @person.avatar.destroy if @person.avatar.present?

    redirect_to edit_person_path(@person)
  end

  def remove_subordinate
    @person.remove_subordinate(params[:subordinate_id])

    @person.all_visible_subordinates(params[:page], @limit)
    respond_to do |format|
      format.html { redirect_to controller: 'people', action: 'show', tab: 'subordinates', id: @person.id}
      format.js
    end
  end

  def autocomplete_for_person
    @people = User.active.sorted.like(params[:q]).limit(10)
    @people = @people.visible if Person.respond_to?(:visible)
    @people = @people.to_a
    render layout: false
  end

  private

  def authorize_people
    allowed = case params[:action].to_s
      when 'create', 'new'
        User.current.allowed_people_to?(:add_people, @person)
      when 'update', 'edit', 'destroy_avatar', 'remove_subordinate'
        User.current.allowed_people_to?(:edit_people, @person)
      when 'destroy'
        User.current.allowed_people_to?(:delete_people, @person)
      when 'index'
        User.current.allowed_people_to?(:view_people, @person)
      when 'show', 'load_tab'
        User.current.allowed_people_to?(:view_people, @person) && access_to_tab?
      else
        false
      end

    deny_access unless allowed
    allowed
  end

  def access_to_tab?
    case params[:tab] || params[:tab_name]
    when 'performance'
      User.current.allowed_people_to?(:view_performance, @person)
    else
      true
    end
  end

  def attach_avatar
    return if params[:person_avatar].blank?
    params[:person_avatar][:description] = 'avatar'
    @person.avatar.destroy if @person.avatar
    Attachment.attach_files(@person, '1' => params[:person_avatar])
    render_attachment_warning_if_needed(@person)
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    content_type = Redmine::MimeType.of(attachment.filename) if content_type.blank?
    content_type.to_s
  end

  def find_person
    id = params[:person_id] || params[:id]
    if id == 'current'
      require_login || return
      @person = User.current
    else
      @person = Person.find(id)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_managers
    if params[:id] == 'new'
      @person  = Person.new(language: Setting.default_language, mail_notification: Setting.default_notification_option)
    else
      find_person
    end
    @managers = @person.available_managers
  end

  def bulk_find_people
    @people = Person.where(id: params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @people.empty?
    if @people.detect { |person| !person.visible? }
      deny_access
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def bulk_edit_access?
    @people && @people.collect { |c| User.current.allowed_people_to?(:edit_people, c) }.inject { |memo, d| memo && d }
  end

  def groups_present?
    groups = Group.where(id: params[:person][:group_ids])
    groups.present?
  end

  def limit_per_page_option
    @limit = per_page_option
  end

  def get_data_for_tab
    tab = params[:tab] || params[:tab_name]
  end
end
