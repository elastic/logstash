# encoding: utf-8
require_relative "environment"
LogStash::Bundler.setup!({:without => [:build]})
require "logstash-core"
require "logstash/environment"

$LOAD_PATH.unshift(File.join(LogStash::Environment::LOGSTASH_CORE, "spec"))

require "rspec/core"
require "rspec"
require 'ci/reporter/rake/rspec_loader'

status = RSpec::Core::Runner.run(ARGV.empty? ? ["spec"] : ARGV).to_i
exit status if status != 0
