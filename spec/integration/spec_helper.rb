# encoding: utf-8
require_relative "support/integration_test_helpers"
require_relative "../../logstash-core/lib/logstash/environment"
require "fileutils"

if LogStash::Environment.windows?
  puts "[integration] Theses integration test are specifically made to be run on under linux/unix"
  puts "[integration] Please see our windows version of the tests https://github.com/elastic/logstash/tree/master/test/windows"
end

# Configure the test environment
source = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
integration_path = File.join(source, "integration_run")

puts "[integration_spec] configure environment"

if Dir.exists?(integration_path)
  # We copy the current logstash into a temporary directory
  # since the tests are a bit destructive
  FileUtils.mkdir_p(integration_path)
  rsync_cmd = "rsync -a --delete --exclude 'rspec' --exclude '#{File.basename(integration_path)}' --exclude 'integration_spec' --exclude '.git' #{source} #{integration_path}"

  puts "[integration_spec] Rsync source code into: #{integration_path}"
  system(rsync_cmd)
  puts "[integration_spec] Finish rsync"

  LOGSTASH_TEST_PATH = File.join(integration_path, "logstash")
else
  LOGSTASH_TEST_PATH = File.expand_path(File.join(File.dirname(__FILE__), ".."))
end

puts "[integration_spec] Running the test in #{LOGSTASH_TEST_PATH}"
puts "[integration_spec] Running specs"

RSpec.configure do |config|
  config.order = "random"
end
