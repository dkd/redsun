require_dependency 'issue'

# :nodoc:
module RedmineRedsun
  module Patches
    # Patches Redmine's Issue dynamically.
    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend ClassMethods
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          searchable do
            # Class Name
            string :class_name, stored: true

            # Issue ID
            text :id, stored: true

            # Active?
            boolean :active, stored: true do
              active?
            end

            # is_private
            boolean :is_private, stored: true

            # Subject
            text :subject, stored: true, boost: 9 do
              subject.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if subject.present?
            end

            # Description
            text :description, stored: true, boost: 7 do
              #RedmineRedsun::Helper::Text.convert_textile_with_tables(description) if description.present?
              description.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if description.present?
            end

            # Project ID
            integer :project_id

            # Journals entries, i.e. status updates, comments, etc.
            text :comments, stored: true, boost: 9 do
              journals.where("journals.notes != ''").map do |j|
                if j.notes.present?
                  j.notes.gsub(/[[:cntrl:]]/,
                               ' ').scan(/[[:print:][:space:]]/).join
                end
              end.join(' ')
            end

            # RedmineUp Tags
            string :tags, stored: true, multiple: true do
              tags.map(&:name) if respond_to?(:tags)
            end

            # Updated at
            time :updated_on

            # Created at
            time :created_on

            # Issue creator
            integer :author_id, references: User

            # Start
            time :start_date

            # Stop
            time :due_date

            # Closed?
            boolean :is_closed

            # Assigned to
            integer :assigned_to_id, references: User

            # Name of Project
            string :project_name, stored: true
          end
        end
      end

      # :nodoc:
      module ClassMethods
      end

      # :nodoc:
      module InstanceMethods
        SORT_FIELDS = %w[updated_on created_on score]
        SORT_ORDER = [%w[ASC label_ascending], %w[DESC label_descending]]

        def class_name
          self.class.name
        end

        def project_name
          project.name if project
        end

        def is_closed
          self.closed?
        end

        def active?
          return false if project.nil?
          project.active?
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineRedsun::Patches::IssuePatch)
  Issue.include RedmineRedsun::Patches::IssuePatch
end
