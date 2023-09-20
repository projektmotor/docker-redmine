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

class AgileSprint < ActiveRecord::Base
  include Redmine::Utils::DateCalculation
  include Redmine::SafeAttributes
  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name',
                  'description',
                  'status',
                  'start_date',
                  'end_date',
                  'sharing'
  OPEN = 0
  ACTIVE = 1
  CLOSED = 2
  STATUSES = { open: OPEN, active: ACTIVE, closed: CLOSED }

  belongs_to :project
  has_many :agile_data, class_name: 'AgileData', dependent: :nullify
  has_many :issues, through: :agile_data

  validates_presence_of :project, :name, :status, :start_date, :end_date
  validates_uniqueness_of :name, scope: [:project_id]
  validate :dates_order
  validate :dates_crossing
  validate :issue_statuses

  before_save :change_active_status

  scope :active, -> { where(status: ACTIVE) }

  scope :for_project, ->(project) { joins(:project).
                                    preload(:project).
                                    where("#{Project.table_name}.status <> ? AND #{AgileSprint.table_name}.project_id = ?",
                                          Project::STATUS_ARCHIVED,
                                          project.try(:id)) }
  scope :available, -> { where(status: [OPEN, ACTIVE]).sorted }
  scope :sorted, -> { order("#{AgileSprint.table_name}.status ASC, #{AgileSprint.table_name}.start_date DESC") }
  scope :system, -> { where(sharing: AgileSprint.sharings[:system]) }
  scope :visible, -> { joins(:project).
                       where(Project.allowed_to_condition(User.current, :view_agile_queries))}
  scope :status, (lambda do |status|
    where(status: status.to_s) if status.present?
  end)

  def self.statuses
    { active: 1, open: 0, closed: 2 }
  end

  def self.sharings
    { none: 0, descendants: 1, hierarchy: 2, tree: 3, system: 4 }
  end

  def self.common_for_projects(projects)
    return [] if projects.blank?

    projects.map(&:shared_agile_sprints).inject { |clc, p_sprints| clc & p_sprints }
  end

  def self.sort_by_status(sprints)
    status_order = [1, 0, 2]
    sprints.sort_by do |element|
      status_order.index(element.status)
    end
  end

  def to_s
    "#{name} (#{interval})"
  end

  def interval
    "#{I18n.l(start_date, format: :short)} - #{I18n.l(end_date, format: :short)}"
  end

  def length
    (end_date - start_date).to_i
  end

  def remaining
    return 0 if Date.today > end_date
    return (end_date - start_date).to_i if start_date > Date.today

    working_days(Date.today, end_date)
  end

  def status_name
    self.class.statuses.key(status)
  end

  def sharing_name
    self.class.sharings.key(sharing)
  end

  def shared_projects
    project_root = project.root? ? project : project.root
    sharing_condition =
      case sharing
      when self.class.sharings[:system]
        '1=1'
      when self.class.sharings[:tree]
        "(#{Project.table_name}.lft >= #{project_root.lft} AND #{Project.table_name}.rgt <= #{project_root.rgt})"
      when self.class.sharings[:descendants]
        "(#{Project.table_name}.lft > #{project.lft} AND #{Project.table_name}.rgt < #{project.rgt})"
      when self.class.sharings[:hierarchy]
        "(#{Project.table_name}.lft < #{project.lft} AND #{Project.table_name}.rgt > #{project.rgt})" +
        " OR (#{Project.table_name}.lft > #{project.lft} AND #{Project.table_name}.rgt < #{project.rgt})"
      else
        '1=0'
      end
    Project.has_module(:agile)
           .where("#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}")
           .where("(#{Project.table_name}.id = %s OR %s)", project.id, sharing_condition)
  end

  private

  def dates_order
    errors.add(:base, l(:label_agile_sprint_errors_end_more_start)) if end_date.nil? || start_date > end_date
  end

  def dates_crossing
    return if RedmineAgile.allow_ovelapping_sprints?

    crossed_sprints = AgileSprint.for_project(project)
                                 .where('(start_date < :start AND :start < end_date) OR (start_date < :end AND :end < end_date)',
                                        start: start_date,
                                        end: end_date)
                                 .where(self_id_condition, id: id)
    return if sharing != self.class.sharings[:none] || crossed_sprints.empty?

    errors.add(:base, l(:label_agile_sprint_errors_crossed))
  end

  def issue_statuses
    errors.add(:base, l(:label_agile_sprint_errors_open_issues)) if status == CLOSED && issues.where(project_id: shared_projects.ids).open.any?
  end

  def change_active_status
    return unless status == ACTIVE

    AgileSprint.active.where(self_id_condition, id: id).where(project_id: project_id).update_all(status: OPEN)
  end

  def self_id_condition
    id.present? ? "#{AgileSprint.table_name}.id != :id" : "#{AgileSprint.table_name}.id IS NOT NULL"
  end
end
