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

module Redmine
  module Acts
    module AttachableGlobal
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_attachable_global(options = {})
          if ActiveRecord::VERSION::MAJOR >= 4
            has_many :attachments, -> { order("#{Attachment.table_name}.created_on") }, **options.merge(as: :container, dependent: :destroy)
          else
            has_many :attachments, options.merge(:as => :container,
                                                 :order => "#{Attachment.table_name}.created_on",
                                                 :dependent => :destroy)
          end

          send :include, Redmine::Acts::AttachableGlobal::InstanceMethods
          before_save :attach_saved_attachments
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def attachments_visible?(user=User.current)
          (respond_to?(:visible?) ? visible?(user) : true)
          # && user.allowed_to?(self.class.attachable_options[:view_permission], self.project)
        end

        def attachments_deletable?(user=User.current)
          (respond_to?(:visible?) ? visible?(user) : true)  && user.allowed_people_to?(:edit_people, self)
        end

        def saved_attachments
          @saved_attachments ||= []
        end

        def unsaved_attachments
          @unsaved_attachments ||= []
        end

        def save_attachments(attachments, author=User.current)
          if attachments.respond_to?(:to_unsafe_hash)
            attachments = attachments.to_unsafe_hash
          end
          if attachments.is_a?(Hash)
            attachments = attachments.values
          end
          if attachments.is_a?(Array)
            attachments.each do |attachment|
              a = nil
              if file = attachment['file']
                next unless file.size > 0
                a = Attachment.create(:file => file, :author => author)
              elsif token = attachment['token']
                a = Attachment.find_by_token(token)
                next unless a
                a.filename = attachment['filename'] unless attachment['filename'].blank?
                a.content_type = attachment['content_type']
              end
              next unless a
              a.description = attachment['description'].to_s.strip
              if a.new_record?
                unsaved_attachments << a
              else
                saved_attachments << a
              end
            end
          end
          {:files => saved_attachments, :unsaved => unsaved_attachments}
        end

        def attach_saved_attachments
          saved_attachments.each do |attachment|
            self.attachments << attachment
          end
        end
        module ClassMethods
        end
      end
    end
  end
end
