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
  module Charts
    module Components
      class BaseComponent
        include ActionView::Helpers::AssetTagHelper
        include ApplicationHelper
        include ActionView::Context
        include ActionView::Helpers::UrlHelper
        include ActionView::Helpers::ControllerHelper
        include Rails.application.routes.url_helpers
        include ERB::Util
        include Redmine::I18n
        include Redmine::Utils::DateCalculation
        include PeopleHelper
        include RedminePeople::Charts::Helpers::ChartHelper
        include RedminePeople::Helper

        include AvatarsHelper if RedminePeople.module_exists?(:AvatarsHelper)

        def render
          raise NotImplementedError
        end

        def config
          ActionController::Base.config
        end
      end
    end
  end
end
