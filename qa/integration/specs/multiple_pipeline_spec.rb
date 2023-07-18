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
require "socket"
require "yaml"

describe "Test Logstash service when multiple pipelines are used" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  let(:temporary_out_file_1) { Stud::Temporary.pathname }
  let(:temporary_out_file_2) { Stud::Temporary.pathname }

  let(:pipelines) {[
    {
      "pipeline.id" => "test",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { generator { count => 1 } } output { file { path => \"#{temporary_out_file_1}\" } }"
    },
    {
      "pipeline.id" => "test2",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { generator { count => 1 } } output { file { path => \"#{temporary_out_file_2}\" } }"
    }
  ]}

  let!(:settings_dir) { Stud::Temporary.directory }
  let!(:pipelines_yaml) { pipelines.to_yaml }
  let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }

  let(:retry_attempts) { 40 }

  let(:pipelines_yaml_file_permissions) { 0644 }

  before(:each) do
    IO.write(pipelines_yaml_file, pipelines_yaml)
    File.chmod(pipelines_yaml_file_permissions, pipelines_yaml_file)
  end

  it "executes the multiple pipelines" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.spawn_logstash("--path.settings", settings_dir, "--log.level=debug")
    try(retry_attempts) do
      expect(logstash_service.exited?).to be(true)
    end
    expect(logstash_service.exit_code).to eq(0)
    expect(File.exist?(temporary_out_file_1)).to be(true)
    expect(IO.readlines(temporary_out_file_1).size).to eq(1)
    expect(File.exist?(temporary_out_file_2)).to be(true)
    expect(IO.readlines(temporary_out_file_2).size).to eq(1)
  end

  context 'effectively-empty pipelines.yml file' do
    let!(:pipelines_yaml) do
      <<~EOYAML
        # this yaml file contains
        # only comments and
        # is effectively empty
      EOYAML
    end

    it 'exits with helpful guidance' do
      logstash_service = @fixture.get_service("logstash")
      status = logstash_service.run('--path.settings', settings_dir, '--log.level=debug')
      expect(status.exit_code).to_not be_zero
      expect(status.stderr_and_stdout).to include('Pipelines YAML file is empty')
    end
  end

  context 'unreadable pipelines.yml file' do
    let(:pipelines_yaml_file_permissions) { 000 }

    it 'exits with helpful guidance' do
      logstash_service = @fixture.get_service("logstash")
      status = logstash_service.run('--path.settings', settings_dir, '--log.level=debug')
      expect(status.exit_code).to_not be_zero
      expect(status.stderr_and_stdout).to include('Failed to read pipelines yaml file', 'Permission denied')
    end
  end

  context 'readable pipelines.yml with invalid YAML contents' do
    let!(:pipelines_yaml) do
      <<~EOYAML
         - pipeline.id: my_id
           pipeline.workers: 1
         # note: indentation not aligned will cause YAML parse error
         pipeline.ordered: true
      EOYAML
    end

    it 'exits with helpful guidance' do
      logstash_service = @fixture.get_service("logstash")
      status = logstash_service.run('--path.settings', settings_dir, '--log.level=debug')
      expect(status.exit_code).to_not be_zero
      expect(status.stderr_and_stdout).to include('Failed to parse contents of pipelines yaml file', 'SyntaxError:')
    end
  end

  describe "inter-pipeline communication" do
    let(:count) { 2 }
    let(:pipelines) do
      [
        {
          "pipeline.id" => "test",
          "config.string" => "input { generator { count => #{count} } } output { pipeline { send_to => testaddr } }"
        },
        {
          "pipeline.id" => "test2",
          "config.string" => "input { pipeline { address => testaddr } } output { file { path => \"#{temporary_out_file_1}\" flush_interval => 0} }"
        }
      ]
    end
    it "can communicate between pipelines" do
      logstash_service = @fixture.get_service("logstash")
      logstash_service.spawn_logstash("--path.settings", settings_dir, "--log.level=debug")
      logstash_service.wait_for_logstash

      # Wait for LS to come up
      i = 0
      until File.exist?(temporary_out_file_1) && IO.readlines(temporary_out_file_1).size >= count
        i += 1
        sleep 1
        break if i > 30
      end
      expect(IO.readlines(temporary_out_file_1).size).to eq(count)

      puts "Done"
    end
  end
end
