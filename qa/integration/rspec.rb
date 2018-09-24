# encoding: utf-8

require 'rubygems'

::Gem.clear_paths

ENV['GEM_HOME'] = ENV['GEM_PATH'] = ::File.expand_path(
    ::File.join(__FILE__, "..", "..", "..", "build", "qa", "integration", "vendor", "jruby", "2.5.0")
)

require "bundler"
::Bundler.setup

require "rspec/core"
require "rspec"

return RSpec::Core::Runner.run($JUNIT_ARGV).to_i
