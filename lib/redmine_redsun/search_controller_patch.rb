require_dependency('search_controller')

module RedmineRedsun
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

    module ClassMethods
    end

    module InstanceMethods

      def pick_search_engine
        if @project.present? && @project.module_enabled?(:redsun)
          redirect_to redsun_search_url(@project, :search_form => {:searchstring => params[:q]})
        else
          true
        end
      end

    end

  end
end

