require_dependency('search_controller')
# :nodoc:
module RedmineRedsun
  module Patches
    # Patches Redmine's SearchController dynamically.
    module SearchControllerPatch
      def self.included(base) # :nodoc:
        base.extend ClassMethods
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          before_action :pick_search_engine
        end
      end

      # :nodoc:
      module ClassMethods
      end

      # :nodoc:
      module InstanceMethods
        def pick_search_engine
          return true unless Setting[:plugin_redmine_redsun]['enable_solr_search_field']
          if @project.present? && params[:scope] == "project"
            redirect_to project_redsun_search_url(project_id: @project, search_form: { searchstring: params[:q], scope: 'project' })
          else
            redirect_to redsun_search_url(search_form: { searchstring: params[:q], scope: 'all_projects' })
          end
        end
      end
    end
  end
end

unless SearchController.included_modules.include?(RedmineRedsun::Patches::SearchControllerPatch)
  SearchController.include RedmineRedsun::Patches::SearchControllerPatch
end
