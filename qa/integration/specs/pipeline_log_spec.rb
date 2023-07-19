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
require "yaml"
require "fileutils"

describe "Test Logstash Pipeline id" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # used in multiple LS tests
    @ls = @fixture.get_service("logstash")
  }

  after(:all) {
    @fixture.teardown
  }

  before(:each) {
    # backup the application settings file -- logstash.yml
    FileUtils.cp(@ls.application_settings_file, "#{@ls.application_settings_file}.original")
  }

  after(:each) {
    @ls.teardown
    # restore the application settings file -- logstash.yml
    FileUtils.mv("#{@ls.application_settings_file}.original", @ls.application_settings_file)
  }

  let(:temp_dir) { Stud::Temporary.directory("logstash-pipelinelog-test") }
  let(:config) { @fixture.config("root") }
  let(:initial_config_file) { config_to_temp_file(@fixture.config("root")) }

  it "should write logs with pipeline.id" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)
    wait_logstash_process_terminate(@ls)
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exist?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /\[logstash.javapipeline\s*\]\[#{pipeline_name}\]/).to be > 0
  end

  it "write pipeline config in logs - source:config string" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)
    wait_logstash_process_terminate(@ls)
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exist?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /Starting pipeline.*"pipeline.sources"=>\["config string"\]/).to be > 0
  end

  it "write pipeline config in logs - source:config file" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-f", "#{initial_config_file}")
    wait_logstash_process_terminate(@ls)
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exist?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /Starting pipeline.*"pipeline.sources"=>\["#{initial_config_file}"\]/).to be > 0
  end

  it "should separate pipeline output in its own log file" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name,
      "pipeline.separate_logs" => true
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)
    wait_logstash_process_terminate(@ls)

    pipeline_log_file = "#{temp_dir}/pipeline_#{pipeline_name}.log"
    expect(File.exist?(pipeline_log_file)).to be true
    content = IO.read(pipeline_log_file)
    expect(content =~ /Pipeline started {"pipeline.id"=>"#{pipeline_name}"}/).to be > 0

    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exist?(plainlog_file)).to be true
    plainlog_content = IO.read(plainlog_file)
    expect(plainlog_content =~ /Pipeline started {"pipeline.id"=>"#{pipeline_name}"}/).to be_nil
  end

  it "should rollover main log file when pipeline.separate_logs is enabled" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name,
      "pipeline.separate_logs" => true
    }
    FileUtils.mkdir_p(File.join(temp_dir, "data"))
    data = File.join(temp_dir, "data")
    settings = settings.merge({ "path.data" => data })
    IO.write(File.join(temp_dir, "logstash.yml"), YAML.dump(settings))

    log_definition = File.read('fixtures/logs_rollover/log4j2.properties')
    expect(log_definition).to match(/appender\.rolling\.policies\.size\.size\s*=\s*1KB/)
    expect(log_definition).to match(/appender\.rolling\.filePattern\s*=\s*.*\/logstash-plain-%d{yyyy-MM-dd}\.log/)
    FileUtils.cp("fixtures/logs_rollover/log4j2.properties", temp_dir)

    @ls.spawn_logstash("--path.settings", temp_dir, "-w", "1", "-e", config)
    wait_logstash_process_terminate(@ls)

    logstash_logs = Dir.glob("logstash-plain*.log", base: temp_dir)
    expect(logstash_logs.size).to eq(2)
    logstash_logs.each do |filename|
      file_size = File.size(File.join(temp_dir, filename))
      # should be 1KB = 1024 but due to end of line rounding the rollover goes a little bit over
      expect(file_size).to be < 1300
    end
  end

  it "rollover of pipeline log file when pipeline.separate_logs is enabled shouldn't create spurious file " do
      pipeline_name = "custom_pipeline"
      settings = {
        "path.logs" => temp_dir,
        "pipeline.id" => pipeline_name,
        "pipeline.separate_logs" => true
      }
      FileUtils.mkdir_p(File.join(temp_dir, "data"))
      data = File.join(temp_dir, "data")
      settings = settings.merge({ "path.data" => data })
      IO.write(File.join(temp_dir, "logstash.yml"), YAML.dump(settings))

      log_definition = File.read('fixtures/logs_rollover/log4j2.properties')
      expect(log_definition).to match(/appender\.routing\.pipeline\.policy\.size\s*=\s*1KB/)
      FileUtils.cp("fixtures/logs_rollover/log4j2.properties", temp_dir)

      @ls.spawn_logstash("--path.settings", temp_dir, "-w", "1", "-e", config)
      wait_logstash_process_terminate(@ls)

      pipeline_logs = Dir.glob("pipeline*.log", base: temp_dir)
      expect(pipeline_logs).not_to include("pipeline_${ctx:pipeline.id}.log")
    end

  it "should not create separate pipelines log files if not enabled" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name,
      "pipeline.separate_logs" => false
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)
    wait_logstash_process_terminate(@ls)

    pipeline_log_file = "#{temp_dir}/pipeline_#{pipeline_name}.log"
    expect(File.exist?(pipeline_log_file)).to be false

    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exist?(plainlog_file)).to be true
    plaing_log_content = IO.read(plainlog_file)
    expect(plaing_log_content =~ /Pipeline started {"pipeline.id"=>"#{pipeline_name}"}/).to be > 0
  end

  def wait_logstash_process_terminate(service)
    num_retries = 100
    try(num_retries) do
      expect(service.exited?).to be(true)
    end
    expect(service.exit_code).to be >= 0
  end
end
