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

module DepartmentsHelper
  include PeopleHelper

  def department_tree(departments, &block)
    Department.department_tree(departments, &block)
  end

  def parent_department_select_tag(department)
    selected = department.parent if department
    # retrieve the requested parent department
    parent_id = (params[:department] && params[:department][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : Department.find(parent_id))
    end
    departments = department ? department.allowed_parents.compact : Department.all
    options = ''
    options << "<option value=''></option>"
    options << department_tree_options_for_select(departments, :selected => selected)
    content_tag('select', options.html_safe, :name => 'department[parent_id]', :id => 'department_parent_id')
  end

  def department_tree_options_for_select(departments, options = {})
    s = ''
    department_tree(departments) do |department, level|
      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => department.id}
      if department == options[:selected] || department.id == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(department))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag = options[:tag] || 'option'
      tag_options.merge!(yield(department)) if block_given?
      s << content_tag(tag, name_prefix + h(department), tag_options)
    end
    s.html_safe
  end

  def department_tree_grouped_options_for_select(departments, options = {})
    content_tag('optgroup', department_tree_options_for_select(departments, options), :label => l('label_department_plural'))
  end

  def department_tree_links(departments, options = {})
    s = ''
    s << "<ul class='department-tree'>"
    s << "<li> #{link_to(l(:label_people_all), :set_filter => 1)} </li>"
    department_tree(departments) do |department, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      s << "<li>" + name_prefix + people_department_link(department , :class => "#{'selected' if @department && department == @department}")
      s << "</li>"
    end
    s << "</ul>"
    s.html_safe
  end

  def org_chart_tree
    content_tag :ul, id: 'org-chart-tree' do
      content_tag :li do
        org_chart_tree_root.html_safe + departments_tree
      end
    end
  end

  def org_chart_tree_root
    if RedminePeople.organization_name.blank?
      link_to(l(:label_people_set_organization_name), people_settings_path)
    else
      RedminePeople.organization_name
    end
  end

  def departments_tree
    return '' if departments_by_parent_id[nil].blank?

    content_tag(:ul) do
      departments_by_parent_id[nil].inject(''.html_safe) do |s, department|
        s + department_tree_li(department)
      end
    end
  end

  def department_tree_li(department)
    s = ''
    (departments_by_parent_id[department.id] || []).each do |d|
      s << department_tree_li(d)
    end

    (department.people.to_a - [department.head]).each do |person|
      s << content_tag(:li) do
        render_tree_node person
      end
    end

    content_tag(:li) do
      render_tree_node(department) + content_tag(:ul, s.html_safe)
    end
  end

  def render_tree_node(object)
    if object.is_a? Person
      render partial: 'departments/org_chart_tree_person_node', locals: { person: object }
    elsif object.is_a? Department
      render partial: 'departments/org_chart_tree_department_node', locals: { department: object }
    end
  end

  def departments_by_parent_id
    @departments_by_parent_id ||= Department.includes(:head, :people)
                                    .all_visible_departments
                                    .group_by(&:parent_id)
  end

  def people_department_link(department, options={})
    p = {:controller => 'people',
     :action => 'index',
     :set_filter => 1,
     :fields => [:status, :department_id],
     :values => {:status => [Principal::STATUS_ACTIVE.to_s], :department_id => [department.id]},
     :operators => {:status => '=', :department_id => '='}}.merge(options)

    link_to department.name, p, options
  end

  def department_tabs
    [{:name => 'activity', :partial => 'activity', :label => l(:label_activity)},
     {:name => 'files', :partial => 'attachments', :label => l(:label_attachment_plural)}
    ]
  end

  def render_department_tabs(tabs)
    if tabs.any?
      render :partial => 'common/department_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

end
