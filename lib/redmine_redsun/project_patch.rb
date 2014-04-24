# encoding: UTF-8
require_dependency 'project'

# Patches Redmine's User dynamically.
module RedmineRedsun
  module ProjectPatch
    def self.included(base) # :nodoc:

      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          
          # Class Name
          string :class_name, stored: true
          
          # Name
          text :name, stored: true
          
          # Description
          text :description, stored: true
          
          # Issue ID
          integer :id
          
          # Active?
          boolean :active, stored: true do 
            active?
          end
          
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

    end

  end
end