require_dependency 'journal'

# :nodoc:
module RedmineRedsun
  # Patches Redmine's Journal dynamically.
  module JournalPatch
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          # ID
          text :id, stored: true

          # Class Name
          string :class_name, stored: true

          # Journal Type
          string :journalized_type

          # Active?
          boolean :active, stored: true do
            active?
          end

          # Notes
          text :notes, stored: true do
            notes.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if notes.present?
          end

          # Project ID
          integer :project_id

          # Created at
          time :created_on, trie: true

          # Issue creator
          integer :author_id, references: User

          # Issue creator
          integer :indice_for_sunspot, stored: true

          # Name of Project
          string :project_name, stored: true

          # Is Private
          boolean :is_private, stored: true
        end
      end
    end

    # :nodoc:
    module ClassMethods
    end

    # :nodoc:
    module InstanceMethods

      def indice_for_sunspot
        if journalized.try(:journals) && journalized.journals.any?
          journalized.journals.map(&:id).index(self.id)+1
        end
      end

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

      def is_private
        if journalized.is_a? Issue
          journalized.is_private
        else
          false
        end
      end
    end
  end
end
