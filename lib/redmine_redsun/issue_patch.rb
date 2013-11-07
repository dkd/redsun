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
          # Issue ID
          integer :id
          # Tracker
          integer :tracker_id, :references => Tracker
          # Subject
          text :subject, :stored => true, :boost => 9
          # Description
          text :description, :stored => true, :boost => 7
          # Project ID
          integer :project_id
          # Journals entries, i.e. status updates, comments, etc.
          text :journals do
            journals.map { |j| j.notes }
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
          # Estimated hours
          # FIXME
          # Assigned to
          integer :assigned_to_id, :references => User
          # Category
          integer :category_id, :references => IssueCategory
        end
     end

    end

    module ClassMethods

    end

    module InstanceMethods
      SORT_FIELDS = ["updated_on", "created_on", "score"]
      SORT_ORDER = [["ASC", "label_ascending"],["DESC", "label_descending"]]
    end

  end
end