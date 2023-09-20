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

class AgileQuery < Query
  include Redmine::SafeAttributes
  include AgileQuery::AgileQueryTotalMethods
  include AgileQuery::AgileQuerySwimlineMethods
  include AgileQuery::AgileQueryBacklogMethods

  attr_reader :truncated

  self.queried_class = Issue
  self.view_permission = :view_issues if Redmine::VERSION.to_s >= '3.4'

  self.available_columns = [
    QueryColumn.new(:id, sortable: "#{Issue.table_name}.id", default_order: 'desc', caption: :label_agile_issue_id),
    QueryColumn.new(:project, groupable: "#{Issue.table_name}.project_id", sortable: "#{Project.table_name}.id"),
    QueryColumn.new(:tracker, sortable: "#{Tracker.table_name}.position", groupable: true),
    QueryColumn.new(:estimated_hours, sortable: "#{Issue.table_name}.estimated_hours"),
    QueryColumn.new(:done_ratio, sortable: "#{Issue.table_name}.done_ratio"),
    QueryColumn.new(:priority, sortable: "#{IssuePriority.table_name}.position", default_order: 'desc', groupable: true),
    QueryColumn.new(:author, sortable: lambda { User.fields_for_order_statement('users') }, groupable: true),
    QueryColumn.new(:category, sortable: "#{IssueCategory.table_name}.name", groupable: "#{Issue.table_name}.category_id"),
    QueryColumn.new(:fixed_version, sortable: lambda { Version.fields_for_order_statement }, groupable: "#{Issue.table_name}.fixed_version_id"),
    QueryColumn.new(:start_date, sortable: "#{Issue.table_name}.start_date"),
    QueryColumn.new(:due_date, sortable: "#{Issue.table_name}.due_date"),
    QueryColumn.new(:created_on, sortable: "#{Issue.table_name}.created_on"),
    QueryColumn.new(:updated_on, sortable: "#{Issue.table_name}.updated_on"),
    QueryColumn.new(:thumbnails, caption: :label_agile_board_thumbnails),
    QueryColumn.new(:description),
    QueryColumn.new(:sub_issues, caption: :label_agile_sub_issues),
    QueryColumn.new(:day_in_state, caption: :label_agile_day_in_state),
    QueryColumn.new(:parent, groupable: "#{Issue.table_name}.parent_id", sortable: "#{AgileData.table_name}.position", caption: :field_parent_issue),
    QueryColumn.new(:assigned_to, sortable: lambda { User.fields_for_order_statement }, groupable: "#{Issue.table_name}.assigned_to_id"),
    QueryColumn.new(:relations, caption: :label_related_issues),
    QueryColumn.new(:last_comment, caption: :label_agile_last_comment),
    QueryColumn.new(:story_points, caption: :label_agile_story_points)
  ]

  self.available_columns << QueryColumn.new(:checklists, caption: :label_checklist_plural) if RedmineAgile.use_checklist?

  def self.build_from_params(params, attributes = {})
    new(attributes).build_from_params(params)
  end
  before_save :set_default_when_appropriate

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_issues, *args)
    scope = eager_load(:project).where("#{table_name}.project_id IS NULL OR (#{base})")

    if user.admin?
      scope.where("#{table_name}.visibility <> ? OR #{table_name}.user_id = ?", VISIBILITY_PRIVATE, user.id)
    elsif user.memberships.any?
      scope.where("#{table_name}.visibility = ?" +
        " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
          "SELECT DISTINCT q.id FROM #{table_name} q" +
          " INNER JOIN #{table_name_prefix}queries_roles#{table_name_suffix} qr on qr.query_id = q.id" +
          " INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = qr.role_id" +
          " INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
          " WHERE q.project_id IS NULL OR q.project_id = m.project_id))" +
        " OR #{table_name}.user_id = ?",
        VISIBILITY_PUBLIC, VISIBILITY_ROLES, user.id, user.id)
    elsif user.logged?
      scope.where("#{table_name}.visibility = ? OR #{table_name}.user_id = ?", VISIBILITY_PUBLIC, user.id)
    else
      scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC)
    end
  }
  scope :only_agile_queries, -> { where(type: AgileQuery.name) }

  def initialize(attributes = nil, *args)
    super attributes
    unless Redmine::VERSION.to_s > '2.4'
      self.filters ||= { 'status_id' => { operator: '*', values: [''] } }
    end
    self.filters ||= {}
    @truncated = false
  end

  def card_columns
    self.inline_columns.select { |c| !%w(day_in_state tracker thumbnails description assigned_to done_ratio spent_hours estimated_hours project id sub_issues checklists last_comment story_points).include?(c.name.to_s) }
  end

  def visible?(user=User.current)
    return true if user.admin?
    return false unless project.nil? || user.allowed_to?(:view_issues, project)
    case visibility
    when VISIBILITY_PUBLIC
      true
    when VISIBILITY_ROLES
      if project
        (user.roles_for_project(project) & roles).any?
      else
        Member.where(user_id: user.id).joins(:roles).where(member_roles: {role_id: roles.map(&:id)}).any?
      end
    else
      user == self.user
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def color_base
    options[:color_base] || RedmineAgile.color_base
  end

  def color_base=(value)
    options[:color_base] = value
  end

  def default_chart
    options[:default_chart]
  end

  def default_chart=(value)
    options[:default_chart] = value
  end

  def chart_unit
    @chart_unit ||= RedmineAgile::Charts::Helper.valid_chart_unit_by(options[:chart], options[:chart_unit])
  end

  def chart_unit=(value)
    options[:chart_unit] = value
  end

  def draw_relations
    r = options[:draw_relations]
    r.nil? || r == '1'
  end

  def draw_relations=(arg)
    options[:draw_relations] = (arg == '0' ? '0' : nil)
  end

  def with_totals?
    Redmine::VERSION.to_s > '3.2' && totalable_columns.any?
  end
  def sprints_enabled
    options[:sprints_enabled] || options[:sprint_id]
  end

  def sprints_enabled=(value)
    options[:sprints_enabled] = value
  end

  def sprint
    return nil unless project

    @sprint ||= project.shared_agile_sprints.where(id: sprint_id).first
  end

  def sprint_id
    return nil unless project
    @sprint_id ||= options[:sprint_id] || project.active_sprint.try(:id) || project.shared_agile_sprints.available.first.try(:id)
  end

  def sprint_id=(val)
    @sprint_id = val
    options[:sprint_id] = val
  end

  def backlog_column
    @backlog_column ||= options[:backlog_column]
  end

  def backlog_column=(val)
    options[:backlog_column] = val
  end

  def is_default?
    !!options[:is_default]
  end

  def is_default=(value)
    options[:is_default] = !!value
  end

  def show_description?
    !!options[:show_description] && sprints_enabled.to_i > 0
  end

  def show_description=(value)
    options[:show_description] = !!value
  end

  def set_as_default
    self.class.where(project_id: self.project_id).where(visibility: self.visibility).where("#{AgileQuery.table_name}.id <> ?", self.id).each do |query|
      query.is_default = false
      query.save
    end if self.is_default?
  end

  def self.default_query(project = nil)
    board_scope = self.visible.includes(:project)
    board_scope = project ? board_scope.where(project_id: [nil, project]) : board_scope.where(project_id: nil)
    default_query = board_scope.where("#{table_name}.visibility = ? AND #{table_name}.user_id = ?", VISIBILITY_PRIVATE, User.current).detect(&:is_default?)
    default_query ||= board_scope.where("#{table_name}.visibility = ?", VISIBILITY_ROLES).detect(&:is_default?)
    default_query ||= board_scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC).detect{|q| q.is_default?}
    default_query.options[:sprints_enabled] = 1 if default_query && default_query.options[:sprints_enabled].nil? && RedmineAgile.sprints_on?
    default_query
  end

  def build_from_params(params)
    params = params.permit!.to_h if params.is_a?(ActionController::Parameters) && Rails.version > '5.0'

    if params[:fields] || params[:f]
      self.filters = {}
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    self.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    self.color_base = params[:color_base] || (params[:query] && params[:query][:color_base])
    self.sprints_enabled = params[:sprints_enabled] || (params[:query] && params[:query][:sprints_enabled]) || (RedmineAgile.sprints_on? ? 1 : 0)
    self.sprint_id = params[:sprint_id] || (params[:query] && params[:query][:sprint_id])

    self.show_description = params[:show_description] || (params[:query] && params[:query][:show_description])

    self.default_chart = params[:default_chart] || (params[:query] && params[:query][:default_chart])
    self.chart_unit = params[:chart_unit] || (params[:query] && params[:query][:chart_unit])
    self.totalable_names = params[:t] || (params[:query] && params[:query][:totalable_names]) || totalable_names if Redmine::VERSION.to_s > '3.2'

    self.is_default = params[:is_default] || (params[:query] && params[:query][:is_default])
    self.backlog_column = params[:backlog_column] || (params[:query] && params[:query][:backlog_column])
    self.options = options.merge({ backlog_column: self.backlog_column })
    self.draw_relations = params[:draw_relations] || (params[:query] && params[:query][:draw_relations])
    if params[:f_status] || params[:wp]
      self.options = options.merge({ :f_status => params[:f_status], :wp => params[:wp] })
    end
    self
  end

  def initialize_available_filters
    principals = []
    subprojects = []
    versions = []
    categories = []
    issue_custom_fields = []

    if project
      principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        principals += Principal.member_of(subprojects)
      end
      versions = project.shared_versions.all
      categories = project.issue_categories.all
      issue_custom_fields = project.all_issue_custom_fields
    else
      if all_projects.any?
        principals += Principal.member_of(all_projects)
      end
      versions = Version.visible.where(sharing: 'system').all
      issue_custom_fields = IssueCustomField.where(is_for_all: true)
    end
    principals.uniq!
    principals.sort!
    users = principals.select { |p| p.is_a?(User) }

    unless Redmine::VERSION.to_s > '2.4'
      add_available_filter 'status_id',
        type: :list_status, values: IssueStatus.sorted.collect{|s| [s.name, s.id.to_s] }
    end

    if project.nil?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("project_id",
        type: :list, values: project_values
      ) unless project_values.empty?
    end

    add_available_filter "tracker_id",
      type: :list, values: trackers.collect{|s| [s.name, s.id.to_s] }
    add_available_filter "priority_id",
      type: :list, values: IssuePriority.all.collect{|s| [s.name, s.id.to_s] }

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("author_id",
      type: :list, values: author_values
    ) unless author_values.empty?

    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    assigned_to_values += (Setting.issue_group_assignment? ?
                              principals : users).collect{|s| [s.name, s.id.to_s] }
    add_available_filter("assigned_to_id",
      type: :list_optional, values: assigned_to_values
    ) unless assigned_to_values.empty?

    group_values = Group.visible.all.collect {|g| [g.name, g.id.to_s] }
    add_available_filter("member_of_group",
      type: :list_optional, values: group_values
    ) unless group_values.empty?

    role_values = Role.givable.collect {|r| [r.name, r.id.to_s] }
    add_available_filter("assigned_to_role",
      type: :list_optional, values: role_values
    ) unless role_values.empty?

    if versions.any?
      fixed_versions = []
      fixed_versions << ["<< #{l(:label_current_version)} >>", 'current_version']
      versions.sort.each{ |s| fixed_versions << ["#{s.project.name} - #{s.name}", s.id.to_s] }
      add_available_filter "fixed_version_id",
        type: :list_optional,
        values: fixed_versions
    end

    if categories.any?
      add_available_filter "category_id",
        type: :list_optional,
        values: categories.collect{|s| [s.name, s.id.to_s] }
    end

    add_available_filter "subject", type: :text
    add_available_filter "created_on", type: :date_past
    add_available_filter "updated_on", type: :date_past
    add_available_filter "closed_on", type: :date_past
    add_available_filter "start_date", type: :date
    add_available_filter "due_date", type: :date
    add_available_filter "estimated_hours", type: :float
    add_available_filter "done_ratio", type: :integer
    add_available_filter "parent_issue_id", type: :relation, values: all_projects_values
    add_available_filter "has_sub_issues", type: :list,
      values: [l(:general_text_yes), l(:general_text_no)],
      label: :label_agile_has_sub_issues
    add_available_filter "version_status", type: :list,
      name: l("label_attribute_of_fixed_version", name: 'status'),
      values: Version::VERSION_STATUSES.collect {|s| [l("version_status_#{s}"), s]}
    add_available_filter "parent_issue_tracker_id", type: :list,
      label: :label_agile_parent_issue_tracker_id,
      values: Tracker.pluck(:name)

    if subprojects.any?
      add_available_filter "subproject_id",
        type: :list_subprojects,
        values: subprojects.collect{|s| [s.name, s.id.to_s] }
    end


    add_custom_fields_filters(issue_custom_fields)

    add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version

    IssueRelation::TYPES.each do |relation_type, options|
      add_available_filter relation_type, type: :relation, label: options[:name], values: all_projects_values
    end

    Tracker.disabled_core_fields(trackers).each { |field|
      delete_available_filter field
    }

    add_available_filter "issue_id", type: :integer, label: :label_issue
    add_available_filter 'description', type: :text

    if User.current.allowed_to?(:set_issues_private, nil, global: true) ||
      User.current.allowed_to?(:set_own_issues_private, nil, global: true)
      add_available_filter 'is_private', type: :list,
                           values: [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]
    end

    if User.current.logged?
      add_available_filter 'watcher_id', type: :list, values: author_values
    end
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += (project ? project.all_issue_custom_fields : IssueCustomField).visible.collect { |cf| QueryCustomFieldColumn.new(cf) }

    if User.current.allowed_to?(:view_time_entries, project, global: true)
      index = nil
      @available_columns.each_with_index { |column, i| index = i if column.name == :estimated_hours}
      index = (index ? index + 1 : -1)
      # insert the column after estimated_hours or at the end
      @available_columns.insert index, QueryColumn.new(:spent_hours,
        sortable: "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)",
        default_order: 'desc',
        caption: :label_spent_time
      )
    end

    if User.current.allowed_to?(:set_issues_private, nil, global: true) ||
      User.current.allowed_to?(:set_own_issues_private, nil, global: true)
      @available_columns << QueryColumn.new(:is_private, sortable: "#{Issue.table_name}.is_private")
    end

    disabled_fields = Tracker.disabled_core_fields(trackers).map { |field| field.sub(/_id$/, '')}
    @available_columns.reject! { |column|
      disabled_fields.include?(column.name.to_s)
    }

    @available_columns.reject! { |column| column.name == :done_ratio} unless Issue.use_field_for_done_ratio?

    @available_columns
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (is_private? && user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public? && !@is_for_all && user.allowed_to?(:manage_public_agile_queries, project, global: true)
  end

  def default_columns_names
    @default_columns_names = RedmineAgile.default_columns.map(&:to_sym)
  end

  def has_column_name?(name)
    columns.detect { |c| c.name == name}
  end

  def groupable_columns
    groupable_method = Redmine::VERSION.to_s > '4.2' ? :groupable? : :groupable
    available_columns.select { |c| c.public_send(groupable_method) && !c.is_a?(QueryCustomFieldColumn) }
  end

  def sql_for_issue_id_field(field, operator, value)
    if operator == "="
      # accepts a comma separated list of ids
      ids = value.first.to_s.scan(/\d+/).map(&:to_i)
      if ids.present?
        "#{Issue.table_name}.id IN (#{ids.join(",")})"
      else
        "1=0"
      end
    else
      sql_for_field("id", operator, value, Issue.table_name, "id")
    end
  end

  def sql_for_watcher_id_field(field, operator, value)
    db_table = Watcher.table_name
    "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND " +
      sql_for_field(field, '=', value, db_table, 'user_id') + ')'
  end

  def sql_for_version_status_field(field, operator, value)
    sql_for_field(field, operator, value, Version.table_name, "status")
  end

  def sql_for_has_sub_issues_field(field, operator, value)
    cond = ''
    cond = 'NOT' if operator == '=' && value.include?(I18n.t(:general_text_no))
    cond = 'NOT' if operator == '!' && value.include?(I18n.t(:general_text_yes))
    "( #{cond} EXISTS ( SELECT * FROM #{Issue.table_name} AS subissues WHERE subissues.parent_id = issues.id ) )"
  end

  def sql_for_parent_issue_id_field(field, operator, value, options={})
    value = value.first.split(',') if value.is_a? Array
    value = value.split(',') if value.is_a? String
    sql = case operator
          when '*', '!*', '=', '!'
            sql_for_field(field, operator, value, queried_table_name, 'parent_id')
          when '=p', '=!p', '!p'
            op = (operator == '!p' ? 'NOT IN' : 'IN')
            comp = (operator == '=!p' ? '<>' : '=')
            "#{Issue.table_name}.parent_id #{op} (SELECT DISTINCT #{Issue.table_name}.id FROM #{Issue.table_name} WHERE #{Issue.table_name}.project_id #{comp} #{value.first.to_i})"
          when '*o', '!o'
            op = (operator == '!o' ? 'NOT IN' : 'IN')
            "#{Issue.table_name}.parent_id #{op} (SELECT DISTINCT #{Issue.table_name}.id FROM #{Issue.table_name} WHERE #{Issue.table_name}.status_id IN (SELECT DISTINCT #{IssueStatus.table_name}.id FROM #{IssueStatus.table_name} WHERE is_closed=#{self.class.connection.quoted_false}))"
          end
    "(#{sql})"
  end

  def sql_for_parent_issue_tracker_id_field(field, operator, value)
    cond = if operator == '=' then '' else 'NOT' end
    selected_trackers_ids = Tracker.where(name: value).pluck(:id).join(',')
    "( EXISTS (SELECT * FROM #{Issue.table_name} AS parents WHERE parents.tracker_id #{cond} IN (#{selected_trackers_ids}) AND parents.id = issues.parent_id ) )"
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups = Group.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      groups = Group.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value).all
    end
    groups ||= []

    members_of_groups = groups.inject([]) {|user_ids, group|
      user_ids + group.user_ids + [group.id]
    }.uniq.compact.sort.collect(&:to_s)

    '(' + sql_for_field("assigned_to_id", operator, members_of_groups, Issue.table_name, "assigned_to_id", false) + ')'
  end

  def sql_for_assigned_to_role_field(field, operator, value)
    case operator
    when "*", "!*" # Member / Not member
      sw = operator == "!*" ? 'NOT' : ''
      nl = operator == "!*" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id FROM #{Member.table_name}" +
        " WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id))"
    when "=", "!"
      role_cond = value.any? ?
        "#{MemberRole.table_name}.role_id IN (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")" :
        "1=0"

      sw = operator == "!" ? 'NOT' : ''
      nl = operator == "!" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id FROM #{Member.table_name}, #{MemberRole.table_name}" +
        " WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id AND #{Member.table_name}.id = #{MemberRole.table_name}.member_id AND #{role_cond}))"
    end
  end

  def sql_for_relations(field, operator, value, options={})
    relation_options = IssueRelation::TYPES[field]
    return relation_options unless relation_options

    relation_type = field
    join_column, target_join_column = "issue_from_id", "issue_to_id"
    if relation_options[:reverse] || options[:reverse]
      relation_type = relation_options[:reverse] || relation_type
      join_column, target_join_column = target_join_column, join_column
    end

    sql = case operator
      when "*", "!*"
        op = (operator == "*" ? 'IN' : 'NOT IN')
        "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}')"
      when "=", "!"
        op = (operator == "=" ? 'IN' : 'NOT IN')
        "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = #{value.first.to_i})"
      when "=p", "=!p", "!p"
        op = (operator == "!p" ? 'NOT IN' : 'IN')
        comp = (operator == "=!p" ? '<>' : '=')
        "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.project_id #{comp} #{value.first.to_i})"
      when "*o", "!o"
        op = (operator == "!o" ? 'NOT IN' : 'IN')
        "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{self.class.connection.quoted_false}))"
      end

    if relation_options[:sym] == field && !options[:reverse]
      sqls = [sql, sql_for_relations(field, operator, value, :reverse => true)]
      sql = sqls.join(["!", "!*", "!p"].include?(operator) ? " AND " : " OR ")
    end
    "(#{sql})"
  end

  IssueRelation::TYPES.keys.each do |relation_type|
    alias_method "sql_for_#{relation_type}_field".to_sym, :sql_for_relations
  end

  def condition_for_status
    if Redmine::VERSION.to_s > '2.4'
      return { status_id: options[:f_status] || IssueStatus.where(is_closed: false) }
    end
    '1=1'
  end

  def issues(options={})
    @issues_cache ||= {}
    return @issues_cache[options.to_s] if @issues_cache.has_key?(options.to_s)

    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
    scope = options[:scope] ? options[:scope] : issue_scope
    scope = scope.
      joins(:status).
      eager_load((options[:include] || []).uniq).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])

    scope = scope.preload(:custom_values)
    scope = scope.preload(:author) if has_column?(:author)
    scope = scope.preload(:agile_color) if color_base == AgileColor::COLOR_GROUPS[:issue]
    scope = scope.preload(:priority => :agile_color) if color_base == AgileColor::COLOR_GROUPS[:priority]

    if color_base == AgileColor::COLOR_GROUPS[:tracker]
      scope = scope.preload(:tracker => :agile_color)
    end

    if has_column_name?(:checklists)
      scope = scope.preload(:checklists)
    end

    if order_option.detect {|x| x.match("agile_data.position")}
      scope = scope.sorted_by_rank
    end

    if has_column_name?(:last_comment)
      journal_comment = Journal.joins(:issue).where("#{Journal.table_name}.notes <> ''").
        where(:issues => {:id => issues_ids(scope)}).order("#{Journal.table_name}.id ASC")
      @last_comments = {}

      journal_comment.each do |lc|
        @last_comments[lc.journalized_id] = lc
      end
    end

    if has_column_name?(:day_in_state)
      @journals_for_state = Journal.joins(:details).where(
        :journals => {
          :journalized_id => issues_ids(scope),
          :journalized_type => "Issue"
        },
        :journal_details => {:prop_key => 'status_id'}).order("created_on DESC")
    end

    @issues_cache[options.to_s] = scope
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
  end

  def issues_ids(scope)
    @issues_ids ||= scope.map(&:id)
  end

  def issues_paginator(issues, page = nil)
    Redmine::Pagination::Paginator.new(issues.count, 20, page)
  end

  def journals_for_state
    @journals_for_state
  end

  def issue_last_comment(issue, options = {})
    return unless has_column_name?(:last_comment) || options[:inline_adding]
    return issue.last_comment unless @last_comments
    @last_comments[issue.id]
  end

  def board_statuses
    return @board_statuses if @board_statuses

    @board_statuses =
      if Redmine::VERSION.to_s > '2.4'
        statuses = Redmine::VERSION.to_s >= '3.4' && project ? project.rolled_up_statuses : board_issue_statuses
        status_filter_values = (options[:f_status] if options)
        if status_filter_values
          result_statuses = statuses.where(id: status_filter_values)
        else
          result_statuses = statuses.where(is_closed: false)
        end
        result_statuses.sorted.map do |s|
          s.instance_variable_set "@issue_count", self.issue_count_by_status[s.id].to_i
          if has_column_name?(:estimated_hours)
            s.instance_variable_set "@estimated_hours_sum", self.issue_count_by_estimated_hours[s.id].to_f
          end
          if RedmineAgile.use_story_points? && has_column_name?(:story_points)
            s.instance_variable_set "@story_points", self.issue_count_by_story_points[s.id].to_i
          end
          if options && options[:wp]
            wp_string = options[:wp][s.id.to_s]
            if /(\d+)-?(\d*)/i =~ wp_string
              s.instance_variable_set("@wp_max", $2.blank? ? $1.to_i : $2.to_i)
              s.instance_variable_set("@wp_min", $1.to_i) if  !$1.blank? && !$2.blank?
            end
          end

          def s.over_wp_limit?
            return false if @wp_max.blank?
            @wp_max.to_i < @issue_count
          end

          def s.under_wp_limit?
            return false if @wp_min.blank?
            @wp_min.to_i > @issue_count
          end

          def s.wp_class
            return 'over_wp_limit' if over_wp_limit?
            'under_wp_limit' if under_wp_limit?
          end
          s
        end
      else
        status_filter_operator = filters.fetch("status_id", {}).fetch(:operator, nil)
        status_filter_values = filters.fetch("status_id", {}).fetch(:values, [])

        result_statuses =
          case status_filter_operator
          when "o"
            board_issue_statuses.where(is_closed: false).sorted
          when "c"
            board_issue_statuses.where(is_closed: true).sorted
          when "="
            board_issue_statuses.where(id: status_filter_values).sorted
          when "!"
            board_issue_statuses.where("#{IssueStatus.table_name}.id NOT IN (" + status_filter_values.map{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")").sorted
          else
            board_issue_statuses.sorted
          end
        result_statuses.map do |s|
          s.instance_variable_set "@issue_count", self.issue_count_by_status[s.id].to_i
          if has_column_name?(:estimated_hours)
            s.instance_variable_set "@estimated_hours_sum", self.issue_count_by_estimated_hours[s.id].to_f
          end
          s
        end
        s
      end
    @board_statuses
  end

  def board_issue_statuses
    return @board_issue_statuses if @board_issue_statuses

    status_ids =
      if tracker_ids = Tracker.eager_load(issues: [{ project: :versions }]).where(statement).pluck(:id)
        WorkflowTransition.where(tracker_id: tracker_ids).distinct.pluck(:old_status_id, :new_status_id).flatten.uniq
      else
        []
      end
    @board_issue_statuses = IssueStatus.where(id: status_ids)
  end

  def issue_count_by_status
    @issue_count_by_status ||= issue_scope.group("#{Issue.table_name}.status_id").count
  end

  def issue_count_by_estimated_hours
    @issue_count_by_estimated_hours ||= issue_scope.group("#{Issue.table_name}.status_id").sum("estimated_hours")
  end

  def issue_count_by_story_points
    @issue_count_by_story_points ||= issue_scope.group("#{Issue.table_name}.status_id").sum("#{AgileData.table_name}.story_points")
  end

  def issue_board
    @truncated = RedmineAgile.board_items_limit <= issue_scope.count
    all_issues = self.issues.limit(RedmineAgile.board_items_limit).sorted_by_rank
    grouped_issues = grouped? ? all_issues.group_by{|i| [i.status_id, i.send("#{self.group_by_column.name}_id")]} : all_issues.group_by{|i| [i.status_id]}
    grouped_issues.values.each{|x|x.sort!{|a,b| a.position.to_i <=> b.position.to_i}} if grouped?
    grouped_issues
          end

  def statement
    incoming_values = filters['fixed_version_id'][:values] if filters['fixed_version_id']

    if values_for('fixed_version_id') == ['current_version'] && project && !current_version
      filters.delete('fixed_version_id')
    elsif values_for('fixed_version_id') && values_for('fixed_version_id').include?('current_version') && project
      # convert identifier of current version to integer
      filters['fixed_version_id'][:values] = incoming_values.map { |el| el == 'current_version' ? current_version.id.to_s : el }
    end

    clauses = super
    # return of incoming filter for correct value in a select on a form
    filters['fixed_version_id'][:values] = incoming_values if incoming_values
    clauses
  end

  private

  def base_agile_query_scope
    Issue.visible
         .eager_load(:status, :project, :assigned_to, :tracker, :priority, :category, :fixed_version, :agile_data)
         .where(agile_projects)
         .where(statement)
         .where(condition_for_status)
  end

  def agile_projects
    return '1=1' unless project

    p_ids = [project.id]
    p_ids += project.descendants.select { |sub| sub.module_enabled?('agile') }.map(&:id) if Setting.display_subprojects_issues? || has_filter?('subproject_id')
    if sprints_enabled.to_i > 0
      sprint_p_ids = Issue.joins(:agile_data)
                         .where("#{AgileData.table_name}.agile_sprint_id = ?", sprint_id).pluck(:project_id).uniq
      p_ids &= sprint_p_ids

    end

    p_ids.any? ? "#{Project.table_name}.id IN (#{p_ids.join(',')})" : '1=0'
  end

  def issue_scope
    return @agile_scope if @agile_scope

    @agile_scope = base_agile_query_scope
    @agile_scope = @agile_scope.where("#{AgileData.table_name}.agile_sprint_id = ?", sprint_id) if sprints_enabled.to_i > 0 && sprint_id.to_i > 0
    @agile_scope
  end

  def project_statement
    unless sprints_enabled.to_i > 0
      return super
    end
    return @project_statement if @project_statement
    return "1=1" unless project

    shared_project_ids = []
    project_ids = [project.id]
    project_ids += project.descendants.map(&:id) if Setting.display_subprojects_issues?

    if has_filter?('subproject_id')
      subprojects_ids = project.descendants.where.not(status: Project::STATUS_ARCHIVED).ids
      case operator_for('subproject_id')
      when '='
        # include the selected subprojects
        project_ids = [project.id] + values_for("subproject_id").map(&:to_i)
      when '!'
        # exclude the selected subprojects
        project_ids = [project.id] + subprojects_ids - values_for("subproject_id").map(&:to_i)
      when '!*'
        # main project only
        project_ids = [project.id]
      else
        # all subprojects
        project_ids = Project.visible.where("#{Project.table_name}.lft >= #{project.lft} AND #{Project.table_name}.rgt <= #{project.rgt}").ids
      end
    else
      shared_project_ids = project.shared_agile_sprints.map(&:shared_projects).map { |projects| projects.map(&:id) }.flatten.uniq
    end

    @project_statement = "#{Project.table_name}.id IN (%s)" % (project_ids | shared_project_ids).join(',')
  end

  def current_version
    return @current_version if @current_version

    versions = project.shared_versions.open.where("LOWER(#{Version.table_name}.name) NOT LIKE LOWER(?)", 'backlog')
    versions -= versions.select(&:completed?).reverse
    @current_version = versions.to_a.uniq.sort.first
  end
  def set_default_when_appropriate
    set_as_default if options[:is_default]
  end
end
