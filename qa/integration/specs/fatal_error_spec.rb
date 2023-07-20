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
    expect(File.read(log_file)).to match /\[FATAL\]\[org.logstash.Logstash.*?java.lang.AssertionError: a fatal error/m
  end

  it "logs unexpected exception (from Java thread)" do
    config = "input { generator { count => 1 message => 'unexpected' } } "
    config += "filter { ruby { code => 'java.lang.Thread.new { raise java.io.EOFException.new event.get(\"message\") }.start; sleep(1.5)' } }"

    spawn_logstash_and_wait_for_exit! config, timeout

    expect(@logstash.exit_code).to be 0 # normal exit

    log_file = "#{logs_dir}/logstash-plain.log"
    expect(File.exist?(log_file)).to be true
    expect(File.read(log_file)).to match /\[ERROR\]\[org.logstash.Logstash.*?uncaught exception \(in thread .*?java.io.EOFException: unexpected/m
  end

  def spawn_logstash_and_wait_for_exit!(config, timeout)
    @logstash.spawn_logstash('--pipeline.workers=1',
                             '--path.logs', logs_dir,
                             '--path.data', data_dir,
                             '--config.string', config)

    time = Time.now
    while (Time.now - time) < timeout
      sleep(0.1)
      break if @logstash.exited?
    end
    raise 'LS process did not exit!' unless @logstash.exited?
  end
end
