require_dependency('search_controller')
# :nodoc:
module RedmineRedsun
  # Patches Redmine's SearchController dynamically.
  module SearchControllerPatch
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        before_filter :pick_search_engine
      end
    end
    # :nodoc:
    module ClassMethods
    end
    # :nodoc:
    module InstanceMethods
      def pick_search_engine
        return true unless Setting[:plugin_redmine_redsun]['enable_solr_search_field']
        if @project.present?
          search_scope = 'project'
          project_id = @project.id
          redirect_to redsun_project_search_url(project_id: project_id, search_form: { searchstring: params[:q], scope: search_scope })
        else
          search_scope = 'all_projects'
          project_id = nil
          redirect_to redsun_search_url(search_form: { searchstring: params[:q], scope: search_scope, project_id: project_id })
        end
      end
    end
  end
end
