require 'redmine'

Redmine::Plugin.register :redmine_redsun do
  name 'Redmine Redsun Plugin'
  author 'Kieran Hayes'
  description 'This plugin utilizes the sunspot gem for search'
  version '2.1.1'
  url 'http://www.dkd.de'
  author_url 'https://www.dkd.de'
  
  settings default: {
    enable_solr_search_field: false,
    enable_select2_plugin: false
  }, partial: 'settings/redsun_settings'
end

#require_dependency 'redmine_redsun/search_controller_patch'
#require_dependency 'redmine_redsun/issue_patch'

Rails.configuration.to_prepare do
  unless SearchController.included_modules.include? RedmineRedsun::SearchControllerPatch
    SearchController.send(:include, RedmineRedsun::SearchControllerPatch) 
  end

  Project.send(:include, RedmineRedsun::ProjectPatch) unless Project.included_modules.include? RedmineRedsun::ProjectPatch
  Issue.send(:include, RedmineRedsun::IssuePatch) unless Issue.included_modules.include? RedmineRedsun::IssuePatch
  WikiPage.send(:include, RedmineRedsun::WikiPagePatch) unless WikiPage.included_modules.include? RedmineRedsun::WikiPagePatch
  Journal.send(:include, RedmineRedsun::JournalPatch) unless Journal.included_modules.include? RedmineRedsun::JournalPatch
  Attachment.send(:include, RedmineRedsun::AttachmentPatch) unless Attachment.included_modules.include? RedmineRedsun::AttachmentPatch
  News.send(:include, RedmineRedsun::NewsPatch) unless News.included_modules.include? RedmineRedsun::NewsPatch
  
  unless ActiveSupport::TestCase.included_modules.include? RedmineRedsun::ActiveSupport::TestCasePatch
    ActiveSupport::TestCase.send(:include, RedmineRedsun::ActiveSupport::TestCasePatch)
  end
end
