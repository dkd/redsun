require_dependency 'news'

# :nodoc:
module RedmineRedsun
  # Patches Redmine's News dynamically.
  module NewsPatch
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          # Class Name
          string :class_name, stored: true

          # Title
          text :title, stored: true

          # News ID
          integer :id

          # Creator
          integer :author_id, references: User

          # Description
          text :description, stored: true

          # Summary
          text :summary, stored: true

          # Project ID
          integer :project_id

          # Created at
          time :created_on, trie: true

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
      SORT_FIELDS = %w(updated_on created_on score)
      SORT_ORDER = [%w(ASC label_ascending), %w(DESC label_descending)]

      def class_name
        self.class.name
      end

      def project_name
        project.name if project
      end
      
      def project_id
        project.id if project
      end

      def active?
        return false if project.nil?
        project.active?
      end

      def description_for_search
        fields = []
        fields << summary if summary.present?
        fields << description if description.present?
        fields.compact.join(' ')
      end

    end
  end
end