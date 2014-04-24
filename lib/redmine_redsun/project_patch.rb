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

          # Project id
          integer :project_id, using: :id

          # Active?
          boolean :active, stored: true do 
            active?
          end

          # Name of Project
          string :project_name, using: :name, stored: true
        end
     end

    end

    module ClassMethods

    end

    module InstanceMethods

      def class_name
        self.class.name
      end

    end

  end
end