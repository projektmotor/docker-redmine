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

require File.expand_path('../../test_helper', __FILE__)

class PeopleHolidaysControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_holidays, :departments, :people_information, :custom_fields, :custom_values, :attachments])

  def setup
    @holiday = PeopleHoliday.find(1)
    @holiday_params = { :name => 'New holiday',
                        :start_date => '2017-05-09',
                        :end_date => '',
                        :description => '',
                        :is_workday => ''
                      }
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
    set_fixtures_attachments_directory

    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  def access_message(action)
    "No access for the #{action} action"
  end

  def test_without_authorization
    # Get
    [:index, :new, :edit].each do |action|
      compatible_request :get, action, :id => @holiday.id
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @holiday.id
      assert_response 302, access_message(action)
    end
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Get
    [:index, :new, :edit].each do |action|
      compatible_request :get, action, :id => @holiday.id
      assert_response 403, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @holiday.id
      assert_response 403, access_message(action)
    end
  end

  def test_with_access_rights
    PeopleAcl.create(2, ['view_people', 'manage_calendar'])
    @request.session[:user_id] = 2

    compatible_request :get, :index
    assert_response :success

    # Get
    [:new, :edit].each do |action|
      compatible_request :get, action, :id => @holiday.id
      assert_response :success
    end

    # Post
    compatible_request :post, :create, :id => @holiday.id
    assert_response :success

    [:update, :destroy].each do |action|
      compatible_request :post, action, :id => @holiday.id
      assert_response 302
    end
  end

  def test_create
    @request.session[:user_id] = 1
    compatible_request :post, :create, :holiday => @holiday_params
    holiday = PeopleHoliday.last
    assert_response 302
    assert_redirected_to :action => 'index'
    assert_equal ['New holiday'], [holiday.name]
  end

  def test_update
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => '1', :holiday => { :name => 'New one holiday' }
    holiday = PeopleHoliday.find(1)
    assert_response 302
    assert_redirected_to :action => 'index'
    assert_equal ['New one holiday'], [holiday.name]
  end

  def test_holiday_notification
    @request.session[:user_id] = 1
    @holiday_params[:notify] = 'all'
    compatible_request :post, :create, :holiday => @holiday_params
    holiday = PeopleHoliday.last
    assert_match holiday.name, last_email.text_part.to_s
  end

  def test_should_send_mail_after_create_people_holiday
    @request.session[:user_id] = 1
    assert_equal ActionMailer::Base.deliveries.size, 0
    assert_difference 'PeopleHoliday.count' do
      compatible_request :post, :create, holiday: @holiday_params.merge(notify: 'all')
    end
    assert ActionMailer::Base.deliveries.size > 0
  end

  def test_should_not_send_mail_after_create_people_holiday
    @request.session[:user_id] = 1
    assert_difference(-> { ActionMailer::Base.deliveries.size }, 0) do
      assert_difference 'PeopleHoliday.count' do
        compatible_request :post, :create, holiday: @holiday_params
      end
    end
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

  def text_part
    last_email.parts.detect { |part| part.content_type.include?('text/plain') }
  end

  def html_part
    last_email.parts.detect { |part| part.content_type.include?('text/html') }
  end
end
