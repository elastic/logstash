# encoding: utf-8
require_relative 'coverage_helper'
# In order to archive an expected coverage analysis we need to eager load
# all logstash code base, otherwise it will not get a good analysis.
CoverageHelper.eager_load if ENV['COVERAGE']

require "logstash/devutils/rspec/spec_helper"

require "flores/rspec"
require "flores/random"

class JSONIOThingy < IO
  def initialize; end
  def flush; end

  def puts(payload)
    # Ensure that all log payloads are valid json.
    LogStash::Json.load(payload)
  end
end

RSpec.configure do |c|
  Flores::RSpec.configure(c)
end

def installed_plugins
  Gem::Specification.find_all.select { |spec| spec.metadata["logstash_plugin"] }.map { |plugin| plugin.name }
end

RSpec::Matchers.define :ir_eql do |expected|
  match do |actual|
    if expected.java_kind_of?(org.logstash.config.ir.SourceComponent) && actual.java_kind_of?(org.logstash.config.ir.SourceComponent)
      expected.sourceComponentEquals(actual)
    else
      return false
    end    
  end
  
  failure_message do |actual|
    "actual value \n#{actual.to_s}\nis not .sourceComponentEquals to the expected value: \n#{expected.to_s}\n"
  end
end
