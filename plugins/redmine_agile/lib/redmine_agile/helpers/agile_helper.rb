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

module RedmineAgile
  module Helpers
    module AgileHelper

      def retrieve_agile_query_from_session
        if session[:agile_query]
          if session[:agile_query][:id]
            @query = AgileQuery.find_by_id(session[:agile_query][:id])
            return unless @query
          else
            @query = AgileQuery.new(get_query_attributes_from_session)
          end
          if session[:agile_query].has_key?(:project_id)
            @query.project_id = session[:agile_query][:project_id]
          else
            @query.project = @project
          end
          @query
        else
          @query = AgileQuery.new(:name => "_")
        end
      end

      def retrieve_agile_query
        if !params[:query_id].blank?
          cond = "project_id IS NULL"
          cond << " OR project_id = #{@project.id}" if @project
          @query = AgileQuery.where(cond).find(params[:query_id])
          raise ::Unauthorized unless @query.visible?
          @query.project = @project
          session[:agile_query] = {:id => @query.id, :project_id => @query.project_id}
          sort_clear
        elsif api_request? || params[:set_filter] || session[:agile_query].nil? || session[:agile_query][:project_id] != (@project ? @project.id : nil)
          @query = AgileQuery.default_query(@project) || AgileQuery.default_query unless params[:set_filter]
          unless @query
            @query = AgileQuery.new(:name => "_", :project => @project)
            @query.build_from_params(params)
          else
            @query.project = @project if @project
          end
          save_query_attribures_to_session(@query)
        else
          # retrieve from session
          @query = nil
          if session[:agile_query] && !session[:agile_query][:id] && !params[:project_id]
            @query = AgileQuery.new(get_query_attributes_from_session)
          end
          @query ||= AgileQuery.default_query(@project) || AgileQuery.default_query

          @query ||= AgileQuery.find_by_id(session[:agile_query][:id]) if session[:agile_query][:id]
          @query ||= AgileQuery.new(get_query_attributes_from_session)
          @query.project = @project
          save_query_attribures_to_session(@query)
        end
      end
      def retrieve_versions_query(klass, session_key)
        if !params[:query_id].blank?
          @query = klass.where(project_id: @project).find(params[:query_id])
          raise ::Unauthorized unless @query.visible?
          @query.project = @project
          session[session_key] = { id: @query.id, project_id: @query.project_id, filters: @query.filters, c: @query.column_names }
          sort_clear
        elsif api_request? || params[:set_filter] || session[session_key].nil? || session[session_key][:project_id] != (@project ? @project.id : nil)
          @query = klass.new(:name => '_')
          @query.project = @project if @project
          @query.build_from_params(params)

          session[session_key] = { project_id: @query.project_id, filters: @query.filters, c: @query.column_names }
        else
          @query = klass.default_query(@project) || klass.default_query
          return if @query

          @query = klass.new(name: '_', filters: session[session_key][:filters])
          @query.project = @project if @project
          @query.build_from_params(session[session_key])
        end
      end
      def agile_query_links(title, queries)
        return '' if queries.empty?
        # links to #index on issues/show
        url_params = {:controller => 'agile_boards', :action => 'index', :project_id => @project}

        content_tag('h3', title) + "\n" +
          content_tag('ul',
            queries.collect {|query|
                css = 'query'
                css << ' selected' if query == @query
                content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
              }.join("\n").html_safe,
            :class => 'queries'
          ) + "\n"
      end

      def link_to_persisted_agile_chart(query, project = @project)
        link_to query.name,
                { controller: 'agile_charts', action: 'show', query_id: query.id, project_id: project },
                class: ('selected' if query.is_a?(AgileChartsQuery) && params[:query_id] && params[:query_id] == query.id.to_s)
      end

      def sidebar_agile_queries
        # Select project specific queries and global queries
        @sidebar_agile_queries ||=
          AgileQuery.only_agile_queries
            .visible
            .where(@project.nil? ? ['project_id IS NULL'] : ['project_id IS NULL OR project_id = ?', @project.id])
            .order("#{Query.table_name}.name ASC")
      end

      def render_sidebar_agile_queries
        out = ''.html_safe
        out << agile_query_links(l(:label_agile_my_boards), sidebar_agile_queries.select { |q| !q.is_public? })
        out << agile_query_links(l(:label_agile_board_plural), sidebar_agile_queries.reject { |q| !q.is_public? })
        out
      end

      def options_card_colors_for_select(selected, options={})
        color_base = [[l(:label_agile_color_no_colors), "none"],
          [l(:label_issue), "issue"],
          [l(:label_tracker), "tracker"],
          [l(:field_priority), "priority"],
          [l(:label_spent_time), "spent_time"],
          [l(:field_assigned_to), "user"]]
        color_base << [l(:field_project), 'project'] if (@project && @project.children.any?) || !@project
        options_for_select(color_base.compact, selected)
      end

      def options_charts_for_select(selected)
        container = []
        RedmineAgile::Charts::Helper::AGILE_CHARTS.each { |k, v| container << [l(v[:name]), k] }
        selected_chart = RedmineAgile::Charts::Helper.chart_by_alias(selected) || selected
        options_for_select(container, selected_chart)
      end

      def grouped_options_charts_for_select(selected)
        grouped_options = {}
        container = []

        RedmineAgile::Charts::Helper::AGILE_CHARTS.each do |chart, value|
          if RedmineAgile::Charts::Helper::CHARTS_WITH_UNITS.include?(chart)
            group = l(value[:name])
            grouped_options[group] = []
            value[:aliases].each do |alias_name|
              grouped_options[group] << ["#{group} (#{l(RedmineAgile::Charts::Helper.chart_unit_label_by(alias_name))})", alias_name]
            end
          else
            container << [l(value[:name]), chart]
          end
        end

        grouped_options_for_select(grouped_options, selected) + options_for_select(container, selected)
      end

      def options_chart_units_for_select(selected = nil)
        container = []
        RedmineAgile::Charts::Helper::CHART_UNITS.each { |k, v| container << [l(v), k] }
        selected_unit = RedmineAgile::Charts::Helper::CHART_UNIT_BY_ALIAS[selected] || selected
        options_for_select(container, selected_unit)
      end

      def render_agile_chart(chart_name, issues_scope)
        render partial: "agile_charts/chart",
              locals: { chart: chart_name, issues_scope: issues_scope, chart_unit: params[:chart_unit] }
      end

      def upgrade_to_pro_agile_chart_link(chart_name, query = @query, current_chart = @chart)
        link_to l("label_agile_charts_#{chart_name}"), '#',
                onclick: "showModal('upgrade-to-pro', '557px');",
                class: ('selected' if query.is_a?(AgileChartsQuery) && query.new_record? && current_chart == chart_name)
      end

      private

      def get_query_attributes_from_session
        attributes = { name: '_',
                      filters: session[:agile_query][:filters],
                      group_by: session[:agile_query][:group_by],
                      column_names: session[:agile_query][:column_names],
                      sprints_enabled: session[:agile_query][:sprints_enabled],
                      backlog_column: session[:agile_query][:backlog_column],
                      default_chart: session[:agile_query][:default_chart],
                      color_base: session[:agile_query][:color_base] }
        (attributes[:options] = session[:agile_query][:options] || {}) if Redmine::VERSION.to_s > '2.4'
        attributes
      end

      def save_query_attribures_to_session(query)
        session[:agile_query] = { project_id: query.project_id,
                                  filters: query.filters,
                                  group_by: query.group_by,
                                  color_base: (query.respond_to?(:color_base) && query.color_base),
                                  sprints_enabled: (query.respond_to?(:sprints_enabled) && query.sprints_enabled.to_i > 0),
                                  backlog_column: (query.respond_to?(:backlog_column) && query.backlog_column),
                                  default_chart: (query.respond_to?(:default_chart) && query.default_chart),
                                  column_names: query.column_names }
        (session[:agile_query][:options] = query.options) if Redmine::VERSION.to_s > '2.4'
      end
    end
  end
end

ActionView::Base.send :include, RedmineAgile::Helpers::AgileHelper
