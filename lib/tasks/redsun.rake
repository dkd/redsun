namespace :redsun do
  task reindex: :environment do
    raise "use PROJECTS=123,234 to index specific projects" if ENV["PROJECTS"].nil?
    projects = ENV["PROJECTS"].split(",").map(&:strip)
    projects.each do |p|
      reindex(Project.find(p))
    end
  end
end

def reindex(project)
  project.index!
  project.issues.each do |issue| 
    issue.index!
  end
  project.wiki.pages.each do |wikipage|
    wikipage.index!
  end
end