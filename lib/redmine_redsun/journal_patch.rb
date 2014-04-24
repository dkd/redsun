# encoding: UTF-8
require_dependency 'journal'

# Patches Redmine's User dynamically.
module RedmineRedsun
  module JournalPatch
    def self.included(base) # :nodoc:

      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          
          # Class Name
          string :class_name, stored: true
          
          # Journal Type
          string :journalized_type
          
          # Active?
          boolean :active, stored: true do
            active?
          end
          
          # Notes
          text :notes, :stored => true, :boost => 9 do
            notes.scan(/[[:print:]]/).join if notes.present?
          end

          # Project ID
          integer :project_id

          # Created at
          time :created_on, :trie => true
          
          # Issue creator
          integer :author_id, :references => User
          
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
      
      def active?
        return false if project.nil?
        project.active?
      end
      
      def project_id
        project.id if project
      end
      
      def project_name
        project.name if project
      end
      
      def author_id
        user.id
      end
      
    end

  end
end