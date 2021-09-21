require_dependency 'attachment'

# :nodoc:
module RedmineRedsun
  # Patches Redmine's attachments dynamically.
  module AttachmentPatch
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        searchable do
          # Class Name
          string :class_name, stored: true

          # Attachment ID
          integer :id
          
          # File Size
          integer :filesize

          # Attachment creator
          integer :author_id, references: User

          # Number of downloads
          integer :downloads

          # File Type
          string :filetype do
            File.extname(filename).gsub(/^\.+/, '').try(:downcase)
          end

          # Filename
          text :filename, stored: true do
            filename.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join if filename.present?
          end

          # Description
          string :description, stored: true do
            description_for_search
          end

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
        fields << description if description.present?
        if container.is_a? Document
          fields << container.try(:title)
          fields << container.try(:description)
        end
        fields.compact.join(' ')
      end

    end
  end
end
