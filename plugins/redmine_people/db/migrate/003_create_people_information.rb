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

class CreatePeopleInformation < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def self.up
    create_table :people_information , :id => false do |t|
      t.primary_key :user_id
      t.string :phone
      t.string :address
      t.string :skype
      t.date :birthday
      t.string :job_title
      t.string :company
      t.string :middlename
      t.integer :gender, :limit => 1
      t.string :twitter
      t.string :facebook
      t.string :linkedin
      t.text :background
      t.date :appearance_date
      t.integer :department_id
    end
  end

  def self.down
    drop_table :people_information
  end

end
