# encoding: utf-8
#
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

module AgileBoardsHelper
  def agile_color_class(issue, options={})
    if options[:color_base]
      color = case options[:color_base]
      when AgileColor::COLOR_GROUPS[:issue]
        issue.color
      when AgileColor::COLOR_GROUPS[:tracker]
        issue.tracker.color
      when AgileColor::COLOR_GROUPS[:priority]
        issue.priority.color
      when AgileColor::COLOR_GROUPS[:spent_time]
        AgileColor.for_spent_time(issue.estimated_hours, issue.spent_hours)
      when AgileColor::COLOR_GROUPS[:project]
        issue.project.color
      end
    else
      color = if RedmineAgile.tracker_colors?
        issue.tracker.color
      elsif RedmineAgile.issue_colors?
        issue.color
      elsif RedmineAgile.priority_colors?
        issue.priority.color
      elsif RedmineAgile.spent_time_colors?
        AgileColor.for_spent_time(issue.estimated_hours, issue.spent_hours)
      end
    end
    "#{RedmineAgile.color_prefix}-#{color}" if color && RedmineAgile.use_colors?
          end

  def agile_user_color(user, options={})
    return if Redmine::VERSION.to_s < '2.4'
    user_color = user.color rescue nil
    user_color ||= AgileColor.for_user(user.login)
    if options[:color_base]
      "border-left: 5px solid #{user_color}".html_safe if options[:color_base] ==  AgileColor::COLOR_GROUPS[:user]
    elsif RedmineAgile.user_color?
      "border-left: 5px solid #{user_color}".html_safe
    end
  end

  def header_th(name, rowspan = 1, colspan = 1, leaf = nil)
    th_attributes = {}
    if leaf
      # th_attributes[:style] = ""
      th_attributes[:style] = "border-bottom: 4px solid; border-bottom-color: #{color_by_name(leaf.name)};" if RedmineAgile.status_colors?
      th_attributes[:"data-column-id"] = leaf.id
      issue_count = leaf.instance_variable_get("@issue_count") || 0
      if Redmine::VERSION.to_s > '2.4'
        wp_count = leaf.instance_variable_get("@wp_max")
        unless wp_count.blank?
          th_attributes[:class] = leaf.wp_class
          issue_count_tag = content_tag(:span, issue_count, :class => leaf.wp_class)
          count_tag = " (#{content_tag(:span, issue_count_tag + "/#{wp_count}", :class => 'count')})".html_safe
        else
          count_tag = " (#{content_tag(:span, issue_count.to_i, :class => 'count')})".html_safe
        end
      else
        count_tag = " (#{content_tag(:span, issue_count.to_i, :class => 'count')})".html_safe
      end
            

      # estimated hours total
      story_points_count = leaf.instance_variable_get("@story_points") || 0
      hours_count = leaf.instance_variable_get("@estimated_hours_sum") || 0
      values = []
      values << '%.2fh' % hours_count.to_f if hours_count > 0
      values << "#{story_points_count}sp" if story_points_count > 0
      if values.present?
        hours_tag = content_tag(:span, values.join('/').html_safe, class: 'hours', title: l(:field_estimated_hours))
      end
    end
    th_attributes[:rowspan] = rowspan if rowspan > 1
    th_attributes[:colspan] = colspan if colspan > 1
    content_tag :th, h(name) + count_tag + hours_tag, th_attributes
  end

  def render_board_headers(columns)
    tree = HeaderTree.new

    columns.map do |column|
      path = column.name.split(':').map(&:strip)
      tree.put path, column
    end

    maxdepth = tree.depth
    ret = tree.render

    columns_headers = ret[1..-1].map do |row|
      row.map do |th_params|
        header_th *th_params
      end
    end

    if @query && @query.backlog_column? && columns_headers.size > 0
      bl_header = content_tag(:th, l(:label_agile_board_backlog), class: 'backlog-column-header', rowspan: columns_headers.size)
      columns_headers.first.unshift(bl_header)
    end

    columns_headers.map { |x| "<tr>#{x.join('')}</tr>" }.join.html_safe
          end

  def color_by_name(name)
    "##{"%06x" % (name.unpack('H*').first.hex % 0xffffff)}"
  end
  def format_swimlane_object(object, html=true)
    case object.class.name
    when 'Array'
      object.map {|o| format_swimlane_object(o, html)}.join(', ').html_safe
    when 'Time'
      format_time(object)
    when 'Date'
      format_date(object)
    when 'Fixnum'
      object.to_s
    when 'Float'
      sprintf "%.2f", object
    when 'User'
      html ? link_to_user(object) : object.to_s
    when 'Project'
      html ? link_to_project(object) : object.to_s
    when 'Version'
      html ? link_to(object.name, version_path(object)) : object.to_s
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue'
      object.visible? && html ? link_to_issue(object) : "##{object.id}"
    else
      html ? h(object) : object.to_s
    end
  end

  def render_board_fields_selection(query)
    query.available_inline_columns.reject(&:frozen?).reject{ |c| c.name == :story_points && !RedmineAgile.use_story_points? }.map do |column|
      label_tag('', check_box_tag('c[]', column.name, query.columns.include?(column)) + column.caption, :class => "floating" )
    end.join(" ").html_safe
  end

  def render_board_fields_status(query)
    available_statuses = Redmine::VERSION.to_s >= '3.4' && @project ? @project.rolled_up_statuses : IssueStatus.sorted
    current_statuses = query.options[:f_status] || IssueStatus.where(:is_closed => false).pluck(:id).map(&:to_s)
    wp = query.options[:wp] || {}
    status_tags = available_statuses.map do |status|
      content_tag(:span,
        label_tag('', check_box_tag('f_status[]', status.id, current_statuses.include?(status.id.to_s)
        ) + content_tag(:span, status.to_s), :title => status.to_s) + text_field_tag("wp[#{status.id}]", wp[status.id.to_s],
          :size => 5, :class => 'wp_input', :placeholder => "WIP",
          :title => l(:label_agile_wip_limit)), :class => 'floating'
      )
                end.join(' ').html_safe
    hidden_field_tag('f[]', 'status_id').html_safe +
      hidden_field_tag('op[status_id]', "=").html_safe +
      status_tags
  end

  def render_issue_card_hours(query, issue)
    hours = []
    hours << "%.2f" % issue.total_spent_hours.to_f if query.has_column_name?(:spent_hours) && issue.total_spent_hours > 0
    hours << "%.2f" % issue.estimated_hours.to_f if query.has_column_name?(:estimated_hours) && issue.estimated_hours
    hours = [hours.join('/') + "h"] unless hours.blank?
    hours << "#{issue.story_points}sp" if RedmineAgile.use_story_points? && query.has_column_name?(:story_points) && issue.story_points

    content_tag(:span, "(#{hours.join('/')})", :class => 'hours') unless hours.blank?
  end

  def render_sprint_total_time_story_points(query, sprint)
    sp = query.sprint_total_time_story_points(query, sprint)

    if sp.positive?
      "(#{"%.2f" % sp})sp"
    end
  end

  def agile_progress_bar(pcts, options={})
    pcts = [pcts, pcts] unless pcts.is_a?(Array)
    pcts = pcts.collect(&:round)
    pcts[1] = pcts[1] - pcts[0]
    pcts << (100 - pcts[1] - pcts[0])
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed') : ''.html_safe) +
        (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done') : ''.html_safe) +
        (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo') : ''.html_safe) +
        (legend ? content_tag('td', content_tag('p', legend, :class => 'percent'), :class => 'legend') : ''.html_safe)
      ), :class => "progress progress-#{pcts[0]}", :style => "width: #{width};").html_safe
  end

  def issue_children(issue)
    return unless issue.children.any?
    content_tag :ul do
      issue.children.select{ |x| x.visible? }.each do |child|
        id = if @query.has_column_name?(:tracker) || @query.has_column_name?(:id) then "##{child.id}:&nbsp;" else '' end
        concat "<li class='#{'task-closed' if child.closed?}'><a href='#{issue_path(child)}'>#{id}#{child.subject}</a></li>#{issue_children(child)}".html_safe
      end
    end
  end

  def time_in_state(distance=nil)
    return "" if !distance || !(distance.is_a? Time)
    distance = Time.now - distance
    hours = distance/(3600)
    return "#{I18n.t('datetime.distance_in_words.x_hours', :count => hours.to_i)}" if hours < 24
    "#{I18n.t('datetime.distance_in_words.x_days', :count => (hours/24).to_i)}"
  end

  def class_for_closed_issue(issue, is_version_board)
    return '' if !RedmineAgile.hide_closed_issues_data? && !is_version_board
    return 'closed-issue' if issue.closed?
    ''
  end

  def init_agile_tooltip_info(options={})
    js_code = "function callGetToolTipInfo()
      {
        var url = '#{issue_tooltip_url}';
        agileBoard.getToolTipInfo(this, url);
      }
      $('.tooltip').mouseenter(callGetToolTipInfo);
    "
    return js_code.html_safe if options[:only_code]
    javascript_tag(js_code)
  end

  def estimated_value(issue)
    return (issue.story_points || 0) if RedmineAgile.use_story_points?
    issue.estimated_hours.to_f || 0
  end

  def estimated_time_value(query, issue)
    issue.estimated_hours.to_f if query.has_column_name?(:estimated_hours)
  end

  def story_points_value(query, issue)
    issue.story_points.to_f if query.has_column_name?(:story_points) && RedmineAgile.use_story_points?
  end

  def show_checklist?(issue)
    RedmineAgile.use_checklist? && issue.checklists.any? && User.current.allowed_to?(:view_checklists, issue.project)
  rescue
    false
  end
  def agile_group_totals(query, swimlane)
    return unless Redmine::VERSION.to_s > '3.2'
    totals_by_group = query.totalable_columns.inject({}) do |h, column|
      h[column] = query.total_by_swimlane(swimlane, column)
      h
    end
    totals_by_group.map { |column, t| total_tag(column, t) }.join(' ').html_safe
  end

  def agile_render_query_totals(query)
    return unless Redmine::VERSION.to_s > '3.2'
    return if query.totalable_columns.blank? && !query.show_description?

    totals_html = render_query_totals(query).to_s.gsub(/<\/*?p.*?>/, '')
    if query.sprints_enabled.to_i > 0 && query.sprint
      interval_html =
        content_tag('span', class: 'agile-sprint-interval') do
          content_tag('span', "#{l(:label_agile_board_totals_interval)}: ") +
            content_tag('span', query.sprint.interval, class: 'value')
        end
      remaining_html =
        content_tag('span', class: 'agile-sprint-remaining') do
          content_tag('span', "#{l(:label_agile_board_totals_remaining)}: ") +
            content_tag('span', l('datetime.distance_in_words.x_days', count: query.sprint.remaining), class: 'value')
        end
    end
    if query.sprint && query.sprint.description.present? && query.show_description?
      desc_html =
        content_tag('span', class: 'agile-sprint-description') do
          content_tag('span', "#{l(:label_agile_board_totals_description)}: ") +
            content_tag('span', query.sprint.description, class: 'value')
        end
      return content_tag('p', (desc_html.to_s).html_safe + (totals_html + interval_html.to_s + remaining_html.to_s).html_safe, class: 'query-totals observed-desc')
    end
    content_tag('p', (desc_html.to_s).html_safe + (totals_html + interval_html.to_s + remaining_html.to_s).html_safe, class: 'query-totals')
  end
end
