# encoding: utf-8
#
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

module PeopleHelper

  def people_tabs(person)
    tabs = [
      { name: 'activity', partial: 'activity', label: l(:label_activity)},
      { name: 'files', partial: 'attachments', label: l(:label_attachment_plural)},
      { name: 'projects', partial: 'projects', label: l(:label_project_plural)}
    ]

    tabs << { name: 'subordinates', partial: 'subordinates', label: l(:label_people_subordinates)} if person.subordinates.any?
    tabs
  end

  def birthday_date(person)
    ages = person_age(person.age)
    if person.birthday.day == Date.today.day && person.birthday.month == Date.today.month
      "#{l(:label_today).capitalize} #{"(#{ages})" unless ages.blank?}".strip
    else
      "#{person.birthday.day} #{t('date.month_names')[person.birthday.month]} #{"(#{ages.to_i + 1})" unless ages.blank?}".strip
    end
  end

  def person_manager_full_name
    manager = @person.manager_id ? Person.find(@person.manager_id) : ''
    content_tag('span', manager, :class => 'manager')
  end

  def retrieve_people_query
    if params[:query_id].present?
      @query = PeopleQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      session[:people_query] = {:id => @query.id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:people_query].nil?
      # Give it a name, required to be valid
      @query = PeopleQuery.new(:name => "_")
      @query.build_from_params(params)
      session[:people_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = PeopleQuery.find_by(id: session[:people_query][:id]) if session[:people_query][:id]
      @query ||= PeopleQuery.new(:name => "_", :filters => session[:people_query][:filters], :group_by => session[:people_query][:group_by], :column_names => session[:people_query][:column_names])
    end
  end

  # TODO: Perhaps, may move this function into redmine_crm gem
  def people_list_style
    list_styles = people_list_styles_for_select.map(&:last)
    if params[:people_list_style].blank?
      list_style = list_styles.include?(session[:people_list_style]) ? session[:people_list_style] : RedminePeople.default_list_style
    else
      list_style = list_styles.include?(params[:people_list_style]) ? params[:people_list_style] : RedminePeople.default_list_style
    end
    session[:people_list_style] = list_style
  end

  def people_list_styles_for_select
    list_styles = [[l(:label_people_list_excerpt), "list_excerpt"]]
  end

  def people_principals_check_box_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false, :id => nil } #{principal.is_a?(Group) ? l(:label_group) + ': ' + principal.to_s : principal}</label>\n"
    end
    s.html_safe
  end

  def people_principals_radio_button_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ radio_button_tag name, principal.id, false, :id => nil } #{principal.is_a?(Group) ? l(:label_group) + ': ' + principal.to_s : principal}</label>\n"
    end
    s.html_safe
  end

  def change_status_link(person)
    return unless User.current.allowed_people_to?(:edit_people, person) && person.id != User.current.id && !person.admin
    url = {:controller => 'people', :action => 'update', :id => person, :page => params[:page], :status => params[:status], :tab => nil}

    if person.locked?
      link_to l(:button_unlock), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person.registered?
      link_to l(:button_activate), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person != User.current
      link_to l(:button_lock), url.merge(:person => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
  end

  def person_tag(person, options={})
    avatar_size = options.delete(:size) || 16
    if person.visible? && !options[:no_link]
      person_avatar = link_to(avatar(person, size: avatar_size, only_path: options[:only_path]), person_path(person), id: 'avatar')
      person_name = link_to(person.name, person_path(person))
    else
      person_avatar = avatar(person, size: avatar_size, only_path: options[:only_path])
      person_name = person.name
    end

    case options.delete(:type).to_s
    when "avatar"
      person_avatar.html_safe
    when "plain"
      person_name.html_safe
    else
      content_tag(:span, "#{person_avatar} #{person_name}".html_safe, :class => "person")
    end
  end

  def render_people_tabs(tabs)
    if tabs.any?
      render :partial => 'common/people_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

  def cleaned_phone(phone)
    phone.scan(/[\d+()-]+/).join
  end

  def metric_deviation_html(previous, current, options = {})
    return if previous.blank? || current.blank?

    content_tag :span, class: 'change', title: deviation_label(previous, current, options) do
      if current == previous
        '0%'
      else
        content_tag(:span, '', class: arrow_classes(previous, current, options)) +
          "#{calculate_progress(previous, current).round}%"
      end
    end
  end

  def arrow_classes(previous, current, options = {})
    prefix = options.fetch(:positive_metric, true) ? '' : 'mirror_'
    ['caret', (current > previous) ? "#{prefix}pos" : "#{prefix}neg"]
  end

  def deviation_label(previous, current, options = {})
    format = options.fetch(:format, :time)
    deviation = (current - previous).abs

    if format == :time
      previous = hours_with_minutes(previous)
      deviation = hours_with_minutes(deviation)
    else
      previous = previous.round
      deviation = deviation.round
    end

    result = ''
    result << "#{label_period(options[:period])}\n" if options[:period]
    result << "#{l(:label_previous)}: #{previous}\n#{l(:label_people_deviation)}: #{deviation}"
    result.html_safe
  end

  def label_period(period, date_format = '%m.%d')
    "#{l(:label_people_period)}: #{period.first.strftime(date_format)} - #{period.last.strftime(date_format)}"
  end

  def hours_with_minutes(time, label_hour = l(:label_people_hour), label_minute = l(:label_people_minute))
    "#{time.to_i}#{label_hour} #{(60 * (time % 1)).round}#{label_minute}".html_safe
  end

  def options_for_select2_people(selected)
    if selected && (person = Person.all_visible.find_by_id(selected))
      options_for_select([[person.name, person.id]], selected)
    end
  end
end
