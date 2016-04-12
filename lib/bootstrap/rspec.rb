# encoding: utf-8
require_relative "environment"
LogStash::Bundler.setup!({:without => [:build]})
require "logstash/environment"

$LOAD_PATH.unshift(File.join(LogStash::Environment::LOGSTASH_CORE, "spec"))

require "rspec/core"
require "rspec"

require_relative "../rake/rspec"
gemfiles_helpers = GemfileHelpers.new.load
puts "WARNING: You're running the test with the current set of logstash core gems"
puts "---------------------------------------------------------------------------"
gemfiles_helpers.find_core_gems.each do |core_gem|
  puts gemfiles_helpers.gemfile.find(core_gem).inspect
end
puts "---------------------------------------------------------------------------"

status = RSpec::Core::Runner.run(ARGV.empty? ? ["spec"] : ARGV).to_i
exit status if status != 0
