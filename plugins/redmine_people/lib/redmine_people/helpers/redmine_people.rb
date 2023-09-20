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

module RedminePeople
  module Helper
    def person_age(age)
      RedminePeople.hide_age? ? '' : age.to_s
    end

    def department_tree_tag(person, options = {})
      return '' if person.department.blank?
      format_department(person.department, options)
    end

    def format_department(department, options = {})
      department.self_and_ancestors.map do |department|
        link_to department.name, department_path(department.id, options)
      end.join(' &#187; ').html_safe
    end
  end
end

ActionView::Base.send :include, RedminePeople::Helper
