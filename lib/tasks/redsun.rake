#require 'progress_bar'

namespace :redsun do
  desc 'Reindex specific Projects, set PROJECTS=123,234'
  task reindex: :environment do
    fail 'Use PROJECTS=123,234 to index specific projects' if ENV['PROJECTS'].nil?
    projects = ENV['PROJECTS'].split(',').map(&:strip)
    projects.each do |p|
      begin
        project = Project.find(p)
        puts "\n\nIndexing #{project.name}"
        reindex(project)
      rescue ActiveRecord::RecordNotFound
        puts "#{p} could not be found. Did you mispell it?\n\n"
      end
    end
  end

  desc 'Opimize Solr index for suggestions'
  task optimize_index: :environment do
    Sunspot.optimize
  end

end

def reindex(project)
  project.index!

  # Issues
  puts "Indexing issues ..."
  issues = project.issues
  issues_bar = ProgressBar.new(issues.count)
  issues.map do |issue|
    issue.index!
    issue.journals.map &:index!
    issues_bar.increment!
  end

  # Wiki
  puts "\nIndexing wiki ..."
  wikipages = project.try(:wiki).try(:pages)
  if wikipages && wikipages.any?
    wikipages_bar = ProgressBar.new(wikipages.count)
    wikipages.map do |wikipage| 
      wikipage.index!
      wikipages_bar.increment!
    end
  end
  
  # News
  puts "\nIndexing news ..."
  news_entries = project.news
  if news_entries && news_entries.any?
    news_entries_bar = ProgressBar.new(news_entries.count)
    news_entries.map do |news_entry| 
      news_entry.index!
      news_entries_bar.increment!
    end
  end

  # Attachments
  puts "\nIndexing attachments"
  attachments = project.try(:attachments)
  if attachments && attachments.any?
    attachments_bar = ProgressBar.new(attachments.count)
    project.attachments.map do |attachment|
      attachment.index!
      attachments_bar.increment!
    end
  end
end
