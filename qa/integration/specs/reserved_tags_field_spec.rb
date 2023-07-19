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

# reserved tags should accept string and array of string only in rename mode
describe "Guard reserved tags field against incorrect use" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  before(:each) {
    @logstash = @fixture.get_service("logstash")
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
    env["TEMP_PATH"] = test_path
    env
  }
  let(:settings_dir) { Stud::Temporary.directory }

  shared_examples_for 'assign illegal value to tags' do |mode, pipeline_fixture, tags_match, fail_tags_match|
    it "[#{mode}] update tags and _tags successfully" do
      @logstash.env_variables = test_env
      @logstash.spawn_logstash("-f", config_to_temp_file(@fixture.config(pipeline_fixture)),
                               "--event_api.tags.illegal", "#{mode}",
                               "--path.settings", settings_dir)

      Stud.try(num_retries.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
        output = IO.read(File.join(test_path, "#{pipeline_fixture}.log"))
        puts output
        expect(output).to match tags_match
        expect(output).to match fail_tags_match
      end
    end
  end

  describe 'create event' do
    it_behaves_like 'assign illegal value to tags', 'rename', 'create_tags_map', /"tags":\["_tagsparsefailure"\]/, /"_tags":\[{"poison":true}\]/
    it_behaves_like 'assign illegal value to tags', 'warn',  'create_tags_map', /"tags":{"poison":true}/, /(?!_tags)/
    it_behaves_like 'assign illegal value to tags', 'rename', 'create_tags_number', /"tags":\["_tagsparsefailure"\]/, /"_tags":\[\[1,2,3\]\]/
    it_behaves_like 'assign illegal value to tags', 'warn', 'create_tags_number', /"tags":\[1,2,3\]/, /(?!_tags)/
  end

  it "should throw exception when assigning two illegal values" do
    ['rename', 'warn'].each do |mode|
      logstash = @logstash.run_cmd(["bin/logstash", "-e", @fixture.config('set_illegal_tags').gsub("\n", ""),
                                    "--path.settings", settings_dir, "--event_api.tags.illegal", mode],
                                   true, test_env)
      expect(logstash.stderr_and_stdout).to match(/Ruby exception occurred/)
    end
  end
end
