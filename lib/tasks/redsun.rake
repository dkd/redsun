namespace :redsun do
  desc 'Reindex specific Projects, set PROJECTS=123,234'
  task reindex: :environment do
    fail 'Use PROJECTS=123,234 to index specific projects' if ENV['PROJECTS'].nil?
    projects = ENV['PROJECTS'].split(',').map(&:strip)
    projects.each do |p|
      reindex(Project.find(p))
    end
  end
end

def reindex(project)
  project.index!
  project.issues.each(&:index!)
  project.wiki.pages.each(&:index!)
end
