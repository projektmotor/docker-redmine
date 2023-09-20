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

class CreateDayoffs < (Rails.version < '5.1') ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :dayoffs do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :leave_type, index: true, foreign_key: true, null: false
      t.boolean :approved, default: false, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.float :hours_per_day
      t.text :notes

      t.timestamps null: false
    end
  end
end
