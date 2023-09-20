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

class AttachmentsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles,
           :enabled_modules, :issues, :trackers,
           :versions, :wiki_pages, :wikis, :documents

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:departments, :people_information, :attachments])
  def setup
    User.current = nil
    set_fixtures_attachments_directory
  end

  def teardown
    set_tmp_attachments_directory
  end

  def test_download_file_of_department_for_member
    set_tmp_attachments_directory

    @f = Attachment.create(:container => Department.find(2),
                           :file => people_uploaded_file('testfile_1.png', 'image/png'),
                           :filename => 'testfile_1.png',
                           :author => User.find(1))

    @request.session[:user_id] = 2

    compatible_request :get, :download, :id => @f.id
    assert_response :success
    assert_equal 'image/png', @response.content_type
  end

  def test_download_file_of_department_for_non_member
    set_tmp_attachments_directory

    @f = Attachment.create(:container => Department.find(2),
                           :file => people_uploaded_file('testfile_1.png', 'image/png'),
                           :filename => 'testfile_1.png',
                           :author => User.find(1))

    @request.session[:user_id] = 7

    compatible_request :get, :download, :id => @f.id
    assert_response 403
  end
end
