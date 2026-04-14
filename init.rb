require 'redmine'

Redmine::Plugin.register :redmine_redsun do
  name 'Redmine Redsun Plugin'
  author 'Kieran Hayes, Nicolai Reuschling'
  description 'This plugin utilizes the sunspot gem for search'
  version '2.8.0'
  url 'https://www.dkd.de'
  author_url 'https://www.dkd.de'

  settings default: {
    enable_solr_search_field: false,
    enable_select2_plugin: false
  }, partial: 'settings/redsun_settings'
end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end

base_url = File.dirname(__FILE__)
[
  'lib/redmine_redsun/patches/attachment_patch',
  'lib/redmine_redsun/patches/issue_patch',
  'lib/redmine_redsun/patches/journal_patch',
  'lib/redmine_redsun/patches/news_patch',
  'lib/redmine_redsun/patches/project_patch',
  'lib/redmine_redsun/patches/search_controller_patch',
  'lib/redmine_redsun/patches/wiki_page_patch'
].each { |file| require(base_url + '/' + file) }
