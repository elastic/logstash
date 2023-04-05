# encoding: utf-8

# Script to test Bundler leak
# 
# To run, copy script to Logstash folder and run:
# 
# bin/ruby bundler_error_simplified_reproducer.rb
# Util JRuby flags
# -J-Xmx2g
# -J-Djruby.compile.mode=JIT | FORCE | OFF
# -J-Djruby.compile.invokedynamic=false | true
# -J-Djruby.reify.classes=true

require "bundler"

cwd = ::File.expand_path(::File.join(__FILE__, ".."))
puts "current working dir: #{cwd}"

lock_file = Pathname.new(::File.join(cwd, "lockfiles", "Gemfile.lock"))
puts "lock_file is: #{lock_file}"

gemfile_path = ::File.join(cwd, "lockfiles", "logstash-input-cloudwatch")
gemfile = ::File.new(gemfile_path, "r+").read
puts "loaded content of #{gemfile_path}"

builder = Bundler::Dsl.new
builder.eval_gemfile("bundler file", gemfile)
definition = builder.to_definition(lock_file, {})

# the following is the incriminated
puts "Before resolve_remotely!"
definition.resolve_remotely!
