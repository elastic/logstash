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
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

### Logstash Keystore notes #############
# The logstash.keystore password is `keystore_pa9454w3rd` and contains the following entries:
# input.count = 10
# output.path = mypath
# pipeline.id = mypipeline
# tag1 = mytag1
# tag2 = mytag2
# tag3 = mytag3
####################################
describe "Support environment variable in condition" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  before(:each) {
    @logstash = @fixture.get_service("logstash")
    IO.write(File.join(settings_dir, "logstash.yml"), YAML.dump(settings))
    FileUtils.cp(File.expand_path("../../logstash.keystore", __FILE__), settings_dir)
  }

  after(:all) {
    @fixture.teardown
  }

  after(:each) {
    @logstash.teardown
  }

  let(:num_retries) { 50 }
  let(:test_path) { Stud::Temporary.directory }
  let(:test_env) {
    env = Hash.new
    env["BIG"] = "100"
    env["SMALL"] = "1"
    env["APP"] = 'foobar'
    env
  }
  let(:settings_dir) { Stud::Temporary.directory }
  let(:settings) {{"pipeline.id" => "${pipeline.id}"}}
  let(:logstash_keystore_password) { "keystore_pa9454w3rd" }

  it "expands variables and evaluate expression successfully" do
    test_env["TEST_ENV_PATH"] = test_path
    test_env["LOGSTASH_KEYSTORE_PASS"] = logstash_keystore_password

    @logstash.env_variables = test_env
    @logstash.start_background_with_config_settings(config_to_temp_file(@fixture.config), settings_dir)

    Stud.try(num_retries.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      output = IO.read(File.join(test_path, "env_variables_condition_output.log")).gsub("\n", "")
      expect(output).to match /Truthy,Not,>,>=,<,<=,==,!=,in,not in,=~,!~,and,more_and,or,nand,xor/
    end
  end

  it "expands variables in secret store" do
    test_env["LOGSTASH_KEYSTORE_PASS"] = logstash_keystore_password
    test_env['TAG1'] = "wrong_env" # secret store should take precedence
    logstash = @logstash.run_cmd(["bin/logstash", "-e",
                                  "input { generator { count => 1 } }
                                    filter { if (\"${APP}\") { mutate { add_tag => \"${TAG1}\"} } }
                                    output { stdout{} }",
                                  "--path.settings", settings_dir],
                                 true, test_env)
    expect(logstash.stderr_and_stdout).to match(/mytag1/)
    expect(logstash.stderr_and_stdout).not_to match(/wrong_env/)
    expect(logstash.exit_code).to be(0)
  end

  it "exits with error when env variable is undefined" do
    test_env["LOGSTASH_KEYSTORE_PASS"] = logstash_keystore_password
    logstash = @logstash.run_cmd(["bin/logstash", "-e", "filter { if \"${NOT_EXIST}\" { mutate {add_tag => \"oh no\"} } }", "--path.settings", settings_dir], true, test_env)
    expect(logstash.stderr_and_stdout).to match(/Cannot evaluate `\$\{NOT_EXIST\}`/)
    expect(logstash.exit_code).to be(1)
  end
end
