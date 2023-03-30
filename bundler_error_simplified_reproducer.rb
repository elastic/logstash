# encoding: utf-8

# Script to test Bundler leak
# 
# To run, copy script to Logstash folder and run:
# 
# bin/ruby bundler_error_simplified_reproducer.rb

require_relative "lib/bootstrap/environment"
require "bundler"

lock_file = Pathname.new(::File.join(LogStash::Environment::LOGSTASH_HOME, "lockfiles", "Gemfile.lock"))
puts "lock_file is: #{lock_file}"

plugin = "logstash-input-cloudwatch"

plugin_gemfile_path = ::File.join(LogStash::Environment::LOGSTASH_HOME, "lockfiles", plugin)  
plugin_gemfile = ::File.new(plugin_gemfile_path, "r+").read
puts "loaded content of #{plugin_gemfile_path}"

builder = Bundler::Dsl.new
builder.eval_gemfile("bundler file", plugin_gemfile)
definition = builder.to_definition(lock_file, {})
definition.resolve_remotely!
