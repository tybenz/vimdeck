require "rubygems"
require "rake"

VERSION = File.read(File.join(".", "VERSION"))

desc "Build gem from gemspec"
task :build do
  exec "gem build vimdeck.gemspec"
end

desc "Deploy gem to rubygems.org"
task :deploy do
  exec "gem push vimdeck-#{VERSION.gsub( /\n/, "" )}.gem"
end

desc "Tag git repo with release"
task :tag do
  exec "git tag v#{VERSION}"
end

desc "Release new version: build, deploy, and tag"
task :release do
  ["build", "deploy", "tag"].each do |t|
    Rake::Task[t].reenable
    Rake::Task[t].invoke
  end
end
