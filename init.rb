require 'redmine'

Redmine::Plugin.register :redmine_redsun do
  name 'Redmine Redsun Plugin'
  author 'Kieran Hayes'
  description 'This plugin utilizes the sunspot gem for search'
  version '0.0.4'
  url 'http://example.com/path/to/plugin'
  author_url 'http://www.dkd.de'
  menu :project_menu, :redsun, { :controller => :redsun_search, :action => :index }, :caption => 'RedSun', :param => :project_id

  project_module :redsun do
    permission :redsun, {:redsun_search => [:index]}
  end
end

require_dependency 'redmine_redsun/search_controller_patch'
require_dependency 'redmine_redsun/issue_patch'

Rails.configuration.to_prepare do
  
  unless SearchController.included_modules.include? RedmineRedsun::SearchControllerPatch
    SearchController.send(:include, RedmineRedsun::SearchControllerPatch) 
  end
  Project.send(:include, RedmineRedsun::ProjectPatch) unless Project.included_modules.include? RedmineRedsun::ProjectPatch
  Issue.send(:include, RedmineRedsun::IssuePatch) unless Issue.included_modules.include? RedmineRedsun::IssuePatch
  WikiPage.send(:include, RedmineRedsun::WikiPagePatch) unless WikiPage.included_modules.include? RedmineRedsun::WikiPagePatch
end