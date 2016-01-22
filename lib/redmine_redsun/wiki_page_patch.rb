require_dependency 'wiki_page'
# :nodoc:
module RedmineRedsun
  # Patches Redmine's WikiPage dynamically.
  module WikiPagePatch
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        after_commit ->{ self.index }
        searchable do
          # ID
          text :id, stored: true

          # Class Name
          string :class_name, stored: true

          # Project ID
          integer :project_id

          # Active?
          boolean :active, stored: true do
            active?
          end

          # Page Title
          text :title, stored: true, boost: 10 do
            title.gsub(/[[:cntrl:]]/, ' ').gsub(/_/, ' ').scan(/[[:print:][:space:]]/).join
          end

          # Content of Page
          text :wiki_content, stored: true, boost: 8 do
            content.text.gsub(/[[:cntrl:]]/, ' ').scan(/[[:print:][:space:]]/).join unless content.nil?
          end

          # Updated at
          time :updated_on, trie: true

          #  Creator
          integer :author_id, references: User do
            content.author_id unless content.nil?
          end
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

      def project_id
        wiki.project_id
      end

      def active?
        wiki.project.active?
      end
    end
  end
end
