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

module AgileVersionsHelper
  def version_select_tag(version, option = {})
    return '' if version.blank?
    version_id = version.is_a?(Version) && version.id || version
    other_version_id = option[:other_version].is_a?(Version) && option[:other_version].id || option[:other_version]
    select_tag('version_id', options_for_select(versions_collection_for_select, selected: version_id, disabled: other_version_id),
                             data: { remote: true,
                                     method: 'get',
                                     url: load_agile_versions_path(version_type: option[:version_type],
                                                                   other_version_id: other_version_id,
                                                                   project_id: @project) }) +
    content_tag(:span, '', :class => "hours header-hours #{option[:version_type]}-hours")
  end

  def versions_collection_for_select
    @project.shared_versions.open.map { |version| [format_version_name(version), version.id.to_s] }
  end

  def estimated_hours(issue)
    "%.2fh" % issue.estimated_hours.to_f
  end

  def estimated_value(issue)
    return (issue.story_points || 0) if RedmineAgile.use_story_points?
    issue.estimated_hours.to_f || 0
  end

  def estimated_unit
    RedmineAgile.use_story_points? ? 'sp' : 'h'
  end

  def column_version_class(tab_version, object)
    if tab_version
      object ? ".version-#{object.id}-issues" : '.no-version-issues'
    else
      object ? ".sprint-#{object.id}-issues" : '.no-sprint-issues'
    end
  end

  def agile_version_query_links(title, queries, sprints = false)
    return '' if queries.empty?
    # links to #index on issues/show
    url_params = { controller: 'agile_versions', action: sprints ? 'sprints' : 'index', project_id: @project}

    content_tag('h3', title) + "\n" +
      content_tag('ul',
        queries.collect { |query|
            css = 'query'
            css << ' selected' if query == @query
            content_tag('li', link_to(query.name, url_params.merge(query_id: query), class: css))
          }.join("\n").html_safe,
        class: 'queries'
      ) + "\n"
  end

  def sidebar_agile_version_queries
    unless @sidebar_agile_version_queries
      @sidebar_agile_version_queries = AgileVersionsQuery.visible.
                                       order("#{Query.table_name}.name ASC").
                                       where('project_id IS NULL OR project_id = ?', @project.id).
                                       all
    end
    @sidebar_agile_version_queries
  end

  def sidebar_agile_sprint_queries
    unless @sidebar_agile_sprint_queries
      @sidebar_agile_sprint_queries = AgileSprintsQuery.order("#{Query.table_name}.name ASC").
                                       where('project_id IS NULL OR project_id = ?', @project.id).
                                       all
    end
    @sidebar_agile_sprint_queries
  end

  def render_sidebar_agile_version_queries
    out = ''.html_safe
    out << agile_version_query_links(l(:label_agile_version_my_boards), sidebar_agile_version_queries.reject(&:is_public?))
    out << agile_version_query_links(l(:label_agile_version_board_plural), sidebar_agile_version_queries.select(&:is_public?))
    out
  end

  def render_sidebar_agile_sprint_queries
    out = ''.html_safe
    out << agile_version_query_links(l(:label_agile_sprint_my_boards), sidebar_agile_sprint_queries.reject(&:is_public?), true)
    out << agile_version_query_links(l(:label_agile_sprint_board_plural), sidebar_agile_sprint_queries.select(&:is_public?), true)
    out
  end
end
