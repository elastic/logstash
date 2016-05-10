# encoding: utf-8
require_relative 'coverage_helper'
# In order to archive an expected coverage analysis we need to eager load
# all logstash code base, otherwise it will not get a good analysis.
CoverageHelper.eager_load if ENV['COVERAGE']

require "logstash/devutils/rspec/spec_helper"
require "logstash/logging/json"

class JSONIOThingy < IO
  def initialize; end
  def flush; end

  def puts(payload)
    # Ensure that all log payloads are valid json.
    LogStash::Json.load(payload)
  end
end

RSpec.configure do |c|
  c.before do
    # Force Cabin to always have a JSON subscriber.  The main purpose of this
    # is to catch crashes in json serialization for our logs. JSONIOThingy
    # exists to validate taht what LogStash::Logging::JSON emits is always
    # valid JSON.
    jsonvalidator = JSONIOThingy.new
    allow(Cabin::Channel).to receive(:new).and_wrap_original do |m, *args|
      logger = m.call(*args)
      logger.level = :debug
      logger.subscribe(LogStash::Logging::JSON.new(jsonvalidator))

      logger
    end
  end

end

def installed_plugins
  Gem::Specification.find_all.select { |spec| spec.metadata["logstash_plugin"] }.map { |plugin| plugin.name }
end


