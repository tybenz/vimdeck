require "rubygems"
require "rake"

VERSION = File.read(File.join(".", "VERSION"))

def build
  exec "gem build vimdeck.gemspec"
end

def deploy
  exec "gem push vimdeck-#{VERSION.gsub( /\n/, "" )}.gem"
end

def tag
  exec "git tag v#{VERSION}"
end

desc "Build gem from gemspec"
task :build do; build end

desc "Deploy gem to rubygems.org"
task :deploy do; deploy end

desc "Tag git repo with release"
task :tag do; tag end

desc "Release new version: build, deploy, and tag"
task :release do
  build
  deploy
  tag
end
