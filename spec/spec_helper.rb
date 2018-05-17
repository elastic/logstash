# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"

require "flores/rspec"
require "flores/random"
require "pathname"
require "stud/task"
require "logstash/devutils/rspec/spec_helper"
require "support/resource_dsl_methods"
require "support/mocks_classes"
require "support/helpers"
require "support/shared_contexts"
require "support/shared_examples"
require 'rspec/expectations'
require "logstash/settings"
require 'rack/test'
require 'rspec'
require "json"
require 'logstash/runner'

class JSONIOThingy < IO
  def initialize; end
  def flush; end

  def puts(payload)
    # Ensure that all log payloads are valid json.
    LogStash::Json.load(payload)
  end
end

# Refactor the suite to https://github.com/elastic/logstash/issues/7148
RSpec::Expectations.configuration.on_potential_false_positives = :nothing

RSpec.configure do |c|
  Flores::RSpec.configure(c)
  c.include LogStashHelper
  c.extend LogStashHelper

  # Some tests mess with LogStash::SETTINGS, and data on the filesystem can leak state
  # from one spec to another; run each spec with its own temporary data directory for `path.data`
  c.around(:each) do |example|
    Dir.mktmpdir do |temp_directory|
      # Some tests mess with the settings. This ensures one test cannot pollute another
      LogStash::SETTINGS.reset

      LogStash::SETTINGS.set("queue.type", "memory")
      LogStash::SETTINGS.set("path.data", temp_directory)

      example.run
    end
  end
end

def installed_plugins
  Gem::Specification.find_all.select { |spec| spec.metadata["logstash_plugin"] }.map { |plugin| plugin.name }
end

