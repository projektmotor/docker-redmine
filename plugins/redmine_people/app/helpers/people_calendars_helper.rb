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

module PeopleCalendarsHelper
  include CalendarsHelper
  include PeopleHelper

  def show_birthdays?
    params[:birthdays].present? || (params[:birthdays].blank? && params[:set_birthdays].blank?)
  end

  def render_person_tooltip(person, options={})
    emails = person.mail.split(/,/).map{|email| "<span class=\"email\" style=\"white-space: nowrap;\">#{mail_to email.strip}</span>"}.join(', ')
    phones = person.phone.split(/,/).map{|phone| "<span class=\"phone\" style=\"white-space: nowrap;\">#{phone.strip}</span>"}.join(', ')

    s = link_to(person.name, person_path(person), options) + "<br /><br />".html_safe
    s <<  "<strong>#{l(:label_people_job_title)}</strong>: #{person.job_title}<br />".html_safe unless person.job_title.blank?
    s <<  "<strong>#{l(:field_mail)}</strong>: #{emails}<br />".html_safe unless person.mail.blank?
    s <<  "<strong>#{l(:label_people_phone)}</strong>: #{phones}<br />".html_safe unless person.phone.blank?
    s
  end
end
