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

require "stud/task"
require "rspec/wait"

def silence_warnings
  warn_level = $VERBOSE
  $VERBOSE = nil
  yield
ensure
  $VERBOSE = warn_level
end

def clear_data_dir
  if defined?(agent_settings)
    data_path = agent_settings.get("path.data")
  else
    data_path = LogStash::SETTINGS.get("path.data")
  end

  Dir.foreach(data_path) do |f|
    next if f == "." || f == ".." || f == ".gitkeep"
    FileUtils.rm_rf(File.join(data_path, f))
  end
end

def mock_settings(settings_values = {})
  settings = LogStash::SETTINGS.clone

  settings_values.each do |key, value|
    settings.set(key, value)
  end

  settings
end

def make_test_agent(settings = mock_settings, config_source = nil)
    sl = LogStash::Config::SourceLoader.new
    sl.add_source(config_source || LogStash::Config::Source::Local.new(settings))
    sl

    ::LogStash::Agent.new(settings, sl)
end

def make_config_source(settings = mock_settings)
  TestPipelineConfigSource.new(settings)
end

##
# This TestPipelineConfigSource can be added to a LogStash::Config::SourceLoader
# to provide pipeline config strings directly for testing purposes.
class TestPipelineConfigSource
  include LogStash::Util::Loggable

  def initialize(settings)
    @settings = settings
    @pipelines = {}
  end

  def add_pipeline(pipeline_id, config_string, settings_overrides = {})
    logger.debug("adding pipeline `#{pipeline_id}` from string `#{config_string}` with additional settings `#{settings_overrides}`")
    @pipelines[pipeline_id.to_sym] = compose_pipeline_config(pipeline_id, config_string, settings_overrides)
  end

  def remove_pipeline(pipeline_id)
    logger.debug("removing pipeline `#{pipeline_id}`")
    !!@pipelines.delete(pipeline_id.to_sym)
  end

  def pipeline_configs
    @pipelines.values
  end

  def match?
    true
  end

  def config_conflict?
    false
  end

  private
  def compose_pipeline_config(pipeline_id, config_string, pipeline_settings)
    config_parts = [org.logstash.common.SourceWithMetadata.new("string", pipeline_id.to_s, config_string)]

    merged_pipeline_settings = @settings.clone.tap do |s|
      s.merge_pipeline_settings('pipeline.id'   => pipeline_id)
      s.merge_pipeline_settings('config.string' => config_string.dup.freeze)
      s.merge_pipeline_settings(pipeline_settings)
    end

    org.logstash.config.ir.PipelineConfig.new(self.class, pipeline_id.to_sym, config_parts, merged_pipeline_settings)
  end
end

def mock_pipeline(pipeline_id, reloadable = true, config_hash = nil)
  config_string = "input { stdin { id => '#{pipeline_id}' }}"
  settings = mock_settings("pipeline.id" => pipeline_id.to_s,
                           "config.string" => config_string,
                           "config.reload.automatic" => reloadable)
  pipeline_config = mock_pipeline_config(pipeline_id, config_string, settings)
  LogStash::JavaPipeline.new(pipeline_config)
end

def mock_java_pipeline_from_string(config_string, settings = LogStash::SETTINGS, metric = nil)
  pipeline_config = mock_pipeline_config(settings.get("pipeline.id"), config_string, settings)
  LogStash::JavaPipeline.new(pipeline_config, metric)
end

def mock_pipeline_config(pipeline_id, config_string = nil, settings = {})
  config_string = "input { stdin { id => '#{pipeline_id}' }}" if config_string.nil?

  # This is for older tests when we already have a config
  unless settings.is_a?(LogStash::Settings)
    settings.merge!({ "pipeline.id" => pipeline_id.to_s })
    settings = mock_settings(settings)
  end

  config_part = org.logstash.common.SourceWithMetadata.new("config_string", "config_string", 0, 0, config_string)

  org.logstash.config.ir.PipelineConfig.new(LogStash::Config::Source::Local, pipeline_id.to_sym, [config_part], settings)
end

def start_agent(agent)
  agent_task = Stud::Task.new do
    begin
      agent.execute
    rescue => e
      raise "Start Agent exception: #{e}"
    end
  end

  wait(30).for { agent.running? }.to be(true)
  agent_task
end

def temporary_file(content, file_name = Time.now.to_i.to_s, directory = Stud::Temporary.pathname)
  FileUtils.mkdir_p(directory)
  target = ::File.join(directory, file_name)

  File.open(target, "w+") do |f|
    f.write(content)
  end
  target
end

RSpec::Matchers.define :ir_eql do |expected|
  match do |actual|
    next unless expected.kind_of?(org.logstash.config.ir.SourceComponent) && actual.kind_of?(org.logstash.config.ir.SourceComponent)

    expected.sourceComponentEquals(actual)
  end

  failure_message do |actual|
    "actual value \n#{actual.to_s}\nis not .sourceComponentEquals to the expected value: \n#{expected.to_s}\n"
  end
end

SUPPORT_DIR = Pathname.new(::File.join(::File.dirname(__FILE__), "support"))
