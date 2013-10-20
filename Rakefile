require "rubygems"
require "rake"

VERSION = File.read(File.join(".", "VERSION"))

desc "Build gem from gemspec"
task :build do
  system "rm *.gem"
  system "gem build vimdeck.gemspec"
end

desc "Deploy gem to rubygems.org"
task :deploy do
  system "gem push vimdeck-#{VERSION.gsub( /\n/, "" )}.gem"
end

desc "Tag git repo with release"
task :tag do
  system "git tag v#{VERSION}"
  puts "Tag v#{VERSION} created"
end

desc "Push tags to github"
task :push_tags do
  system "git push --tags origin master"
end

desc "Release new version: build, deploy, and tag"
task :release do
  ["build", "deploy", "tag", "push_tags"].each do |t|
    Rake::Task[t].reenable
    Rake::Task[t].invoke
  end
end
