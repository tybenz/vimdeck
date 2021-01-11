# -*- encoding: utf-8 -*-
lib = File.expand_path File.join(File.dirname(__FILE__), 'lib')
$:.unshift lib unless $:.include?(lib)

require 'bundler'
require 'rake'

Gem::Specification.new do |s|
  s.name         = 'vimdeck-without-ascii-art'
  s.version      = File.read('VERSION').strip
  s.date         = '2013-09-18'
  s.summary      = 'VIMDECK'
  s.description  = 'VIM as a presentation tool'
  s.authors      = ["Tyler Benziger"]
  s.email        = 'tabenziger@gmail.com'
  s.files        = ['bin/vimdeck']
  s.homepage     = 'http://github.com/tybenz/vimdeck'
  s.license      = 'MIT'
  s.require_paths = ['lib']
  s.files        = FileList['**/**/*'].exclude /.git|.svn|.DS_Store/
  s.bindir       = 'bin'
  s.executables  = ['vimdeck-without-ascii-art']
  s.add_runtime_dependency 'artii', '~>2.0.4'
  s.add_runtime_dependency 'redcarpet', '>=3.1.2', '<3.6.0'
end
