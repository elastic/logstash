# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../framework/fixture'
require_relative '../framework/helpers'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "logstash/devutils/rspec/spec_helper"

describe "uncaught exception" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
  end

  after(:each) do
    @logstash.teardown
    FileUtils.rm_rf(temp_dir)
  end

  let(:timeout) { 90 } # seconds
  let(:temp_dir) { Stud::Temporary.directory("logstash-error-test") }
  let(:logs_dir) { File.join(temp_dir, "logs") }

  # ensure PQ data is isolated.
  # We crash before ACK-ing events, so we need to make sure we don't
  # leave those un-ACK'd events in the queue to poison a subsequent test.
  let(:data_dir) { File.join(temp_dir, "data") }

  it "halts LS on fatal error" do
    config = "input { generator { count => 1 message => 'a fatal error' } } "
    # inline Ruby filter seems to catch everything (including java.lang.Error) so we exercise a thread throwing
    config += "filter { ruby { code => 'Thread.start { raise java.lang.AssertionError.new event.get(\"message\") }' } }"

    spawn_logstash_and_wait_for_exit! config, timeout

    expect(@logstash.exit_code).to be 120

    log_file = "#{logs_dir}/logstash-plain.log"
    expect(File.exist?(log_file)).to be true
    expect(File.read(log_file)).to match /\[FATAL\]\[org\.logstash\.Logstash\s*\].*?java\.lang\.AssertionError: a fatal error/m
  end

  it "logs unexpected exception (from Java thread)" do
    config = "input { generator { count => 1 message => 'unexpected' } } "
    config += "filter { ruby { code => 'java.lang.Thread.new { raise java.io.EOFException.new event.get(\"message\") }.start; sleep(1.5)' } }"

    spawn_logstash_and_wait_for_exit! config, timeout

    expect(@logstash.exit_code).to be 0 # normal exit

    log_file = "#{logs_dir}/logstash-plain.log"
    expect(File.exist?(log_file)).to be true
    expect(File.read(log_file)).to match /\[ERROR\]\[org\.logstash\.Logstash\s*\].*?uncaught exception \(in thread .*?java\.io\.EOFException: unexpected/m
  end

  it "exits when a beats input is running and a Ruby thread raises a Java runtime exception" do
    beats_port = random_port
    ready_flag = File.join(temp_dir, "beats-ready")
    exception_message = "Index -1 out of bounds for length 80"
    # Forward slashes keep the path literal inside the Ruby string on Windows.
    ready_flag_for_ruby = ready_flag.tr("\\", "/")
    init_code = "Thread.new { deadline = Time.now + #{timeout}; sleep 0.1 until File.exist?(\"#{ready_flag_for_ruby}\") || Time.now > deadline; raise java.lang.ArrayIndexOutOfBoundsException.new(\"#{exception_message}\") }"
    config = "input { beats { port => #{beats_port} } } "
    config += "filter { ruby { init => '#{init_code}' code => 'event.set(\"x\", 1)' } } "
    config += "output { stdout { codec => dots } }"

    spawn_logstash_and_wait_for_exit!(config, timeout) do
      wait_for_port(beats_port, timeout)
      if @logstash.exited?
        log_file = "#{logs_dir}/logstash-plain.log"
        log_contents = File.exist?(log_file) ? File.read(log_file) : ""
        raise "LS exited before beats input was ready (status #{@logstash.exit_code})\n#{log_contents}"
      end
      expect(is_port_open?(beats_port)).to be true
      FileUtils.touch(ready_flag)
    end

    # Exit status 1 means the child stopped itself; this example does not signal it.
    expect(@logstash.exit_code).to be 1

    log_file = "#{logs_dir}/logstash-plain.log"
    expect(File.exist?(log_file)).to be true
    log_contents = File.read(log_file)
    expect(log_contents).to match(/\[FATAL\]\[logstash\.runner\s*\].*?An unexpected error occurred!/m)
    expect(log_contents).to match(/ArrayIndexOutOfBoundsException: #{Regexp.escape(exception_message)}/)
    expect(is_port_open?(beats_port)).to be false
  end

  def spawn_logstash_and_wait_for_exit!(config, timeout)
    @logstash.spawn_logstash('--pipeline.workers=1',
                             '--path.logs', logs_dir,
                             '--path.data', data_dir,
                             '--config.string', config)

    yield if block_given?

    time = Time.now
    while (Time.now - time) < timeout
      sleep(0.1)
      break if @logstash.exited?
    end
    raise 'LS process did not exit!' unless @logstash.exited?
  end
end
