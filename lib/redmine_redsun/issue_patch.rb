# encoding: UTF-8
require_dependency 'issue'

# Patches Redmine's User dynamically.
module RedmineRedsun
  module IssuePatch
    def self.included(base) # :nodoc:

      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          
          # Class Name
          string :class_name, stored: true
          # Issue ID
          integer :id
          # Tracker
          integer :tracker_id, :references => Tracker
          
          # Active?
          boolean :active, stored: true do
            active?
          end

          # is_private
          boolean :is_private, stored: true
          
          # Subject
          text :subject, :stored => true, :boost => 9 do
            subject.scan(/[[:print:]]/).join if subject.present?
          end
          # Description
          text :description, :stored => true, :boost => 7 do
            description.scan(/[[:print:]]/).join if description.present?
          end
          # Project ID
          integer :project_id
          # Journals entries, i.e. status updates, comments, etc.
          text :journals do
            journals.map { |j| j.notes.scan(/[[:print:]]/).join if j.notes.present? }
          end
          # Updated at
          time :updated_on, :trie => true
          # Created at
          time :created_on, :trie => true
          # Issue creator
          integer :author_id, :references => User
          # Status
          integer :status_id, :references => IssueStatus

          # Start
          time :start_date, :trie => true
          # Stop
          time :due_date, :trie => true
          # Priority
          integer :priority_id, :references => IssuePriority
          # Assigned to
          integer :assigned_to_id, :references => User
          # Category
          integer :category_id, :references => IssueCategory
          
          # Name of Project
          string :project_name, stored: true
          
        end
     end

    end

    module ClassMethods

    end

    module InstanceMethods
      SORT_FIELDS = ["updated_on", "created_on", "score"]
      SORT_ORDER = [["ASC", "label_ascending"],["DESC", "label_descending"]]
      
      def class_name
        self.class.name
      end
      
      def project_name
        project.name if project
      end
      
      def active?
        return false if project.nil?
        project.active?
      end
      
    end

  end
end