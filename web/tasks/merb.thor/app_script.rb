#!/usr/bin/env ruby

# This was added by Merb's bundler

require "rubygems"
require File.join(File.dirname(__FILE__), "common")

gems_dir = File.join(File.dirname(__FILE__), '..', 'gems')

if File.directory?(gems_dir)
  $BUNDLE = true
  Gem.clear_paths
  Gem.path.replace([File.expand_path(gems_dir)])
  ENV["PATH"] = "#{File.dirname(__FILE__)}:#{ENV["PATH"]}"
  
  gem_file = File.join(gems_dir, "specifications", "<%= spec.name %>-*.gemspec")
  
  if local_gem = Dir[gem_file].last
    version = File.basename(local_gem)[/-([\.\d]+)\.gemspec$/, 1]
  end
end

version ||= "<%= Gem::Requirement.default %>"

if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
  version = $1
  ARGV.shift
end

gem '<%= @spec.name %>', version
load '<%= bin_file_name %>'