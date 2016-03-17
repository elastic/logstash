# encoding: utf-8
require_relative "support/integration_test_helpers"
require "fileutils"

puts "[integration_spec] configure environment"

LOGSTASH_TEST_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

puts "[integration_spec] Running the test in #{LOGSTASH_TEST_PATH}"
puts "[integration_spec] Running specs"

RSpec.configure do |config|
  config.order = "random"
end
