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
require_relative '../framework/settings'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"

describe "Install and run java plugin" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
  end

  after(:all) {
    @logstash.teardown
    @fixture.teardown
  }

  after(:each) {
    # cleanly remove the installed plugin to don't pollute
    # the environment for other subsequent tests
    removal = @logstash_plugin.run_raw("bin/logstash-plugin uninstall #{plugin_name}")

    expect(removal.stderr_and_stdout).to match(/Successfully removed #{plugin_name}/)
    expect(removal.exit_code).to eq(0)
  }

  let(:max_retry) { 120 }
  let!(:settings_dir) { Stud::Temporary.directory }
  let(:plugin_name) { "logstash-input-java_input_example" }
  let(:install_command) { "bin/logstash-plugin install" }

  it "successfully runs a pipeline with an installed Java plugins" do
    execute = @logstash_plugin.run_raw("#{install_command} #{plugin_name}")

    expect(execute.stderr_and_stdout).to match(/Installation successful/)
    expect(execute.exit_code).to eq(0)

    installed = @logstash_plugin.list(plugin_name)
    expect(installed.stderr_and_stdout).to match(/#{plugin_name}/)

    @logstash.start_background_with_config_settings(config_to_temp_file(@fixture.config), settings_dir)

    # wait for Logstash to start
    started = false
    while !started
      begin
        sleep(1)
        result = @logstash.monitoring_api.event_stats
        started = !result.nil?
      rescue
        retry
      end
    end

    Stud.try(max_retry.times, RSpec::Expectations::ExpectationNotMetError) do
      result = @logstash.monitoring_api.event_stats
      expect(result["in"]).to eq(4)
    end
  end
end
