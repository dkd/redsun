require_dependency 'project'
# :nodoc:
module RedmineRedsun
  # Patches Redmine's Project dynamically.
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
          text :name, stored: true do
            name.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if name.present?
          end

          # Description
          text :description, stored: true do
            description.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if description.present?
          end

          # ID
          text :id, stored: true

          # Project id
          integer :project_id, using: :id

          # Active?
          boolean :active, stored: true do
            active?
          end

          # Name of Project
          text :project_name, stored: true, boost: 10 do
            name.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if name.present?
          end
        end
      end
    end

    # :nodoc:
    module ClassMethods
    end
    # :nodoc:
    module InstanceMethods
      def class_name
        self.class.name
      end
    end
  end
end
