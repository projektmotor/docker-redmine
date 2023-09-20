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
  module Hooks
    class HelperIssuesHook < Redmine::Hook::ViewListener

      def helper_issues_show_detail_after_setting(context={})
        if context[:detail].prop_key == 'color'
          detail = context[:detail]
          context[:detail].value = detail.value.blank? ? nil : l(("label_agile_color_" + detail.value.to_s).to_sym)
          context[:detail].old_value = detail.old_value.blank? ? nil : l(("label_agile_color_" + detail.old_value.to_s).to_sym)
        end
      end

    end
  end
end
