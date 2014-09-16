require "logstash/logging"
require 'logstash_helpers'
require "insist"

if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'vendor/'
  end
end

$TESTING = true
if RUBY_VERSION < "1.9.2"
  $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
  raise LoadError
end

$logger = LogStash::Logger.new(STDOUT)
if ENV["TEST_DEBUG"]
  $logger.level = :debug
else
  $logger.level = :error
end

puts("Using Accessor#strict_set for specs")
# mokey path LogStash::Event to use strict_set in tests
# ugly, I know, but this avoids adding conditionals in performance critical section
class LogStash::Event
  def []=(str, value)
    if str == TIMESTAMP && !value.is_a?(LogStash::Timestamp)
      raise TypeError, "The field '@timestamp' must be a LogStash::Timestamp, not a #{value.class} (#{value})"
    end
    @accessors.strict_set(str, value)
  end # def []=
end

RSpec.configure do |config|
  config.extend LogStashHelper
  config.filter_run_excluding :redis => true, :socket => true, :performance => true, :elasticsearch => true, :broken => true, :export_cypher => true
end

