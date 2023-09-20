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
  module Patches
    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def holiday_notification(_user = User.current, holiday, emails)
          redmine_headers 'X-Holiday-Id' => holiday.id
          message_id holiday
          @holiday = holiday
          recipients = emails.join(', ')
          mail to: recipients,
               subject: l(:label_people_holiday_notify_subject,
                          name: holiday.name,
                          from: format_date(holiday.start_date),
                          to: (holiday.end_date.present? ? " - #{format_date(holiday.end_date)}" : ''))
        end
      end
    end
  end
end

unless Mailer.included_modules.include?(RedminePeople::Patches::MailerPatch)
  Mailer.send(:include, RedminePeople::Patches::MailerPatch)
end
