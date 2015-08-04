#!/usr/bin/env ruby

require_relative "environment"

::Gem.clear_paths
::Gem.paths = ENV['GEM_HOME'] = ENV['GEM_PATH'] = LogStash::Environment.logstash_gem_home

begin
  require 'rubygems'
  gem 'rake'
rescue LoadError
end

LogStash::Bundler.setup!({:without => [:build]})
require "logstash/environment"

require 'rake'

Rake.application.run
