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

require "rspec"
require "rspec/expectations"
require "stud/try"

# Match to test `NullObject` pattern
RSpec::Matchers.define :implement_interface_of do |type, key, value|
  match do |actual|
    all_instance_methods_implemented?
  end

  def missing_methods
    expected.instance_methods.select { |method| !actual.instance_methods.include?(method) }
  end

  def all_instance_methods_implemented?
    expected.instance_methods.all? { |method| actual.instance_methods.include?(method) }
  end

  failure_message do
    "Expecting `#{expected}` to implements instance methods of `#{actual}`, missing methods: #{missing_methods.join(",")}"
  end
end

RSpec::Matchers.define :have_actions do |*expected|
  match do |actual|
    expect(actual.size).to eq(expected.size)

    expected_values = expected.each_with_object([]) do |i, obj|
      klass_name = "LogStash::PipelineAction::#{i.first}"
      obj << [klass_name, i.last]
    end

    actual_values = actual.each_with_object([]) do |i, obj|
      klass_name = i.class.name
      obj << [klass_name, i.pipeline_id]
    end

    values_match? expected_values, actual_values
  end
end

RSpec::Matchers.define :have_pipeline? do |pipeline_config|
  match do |agent|
    pipeline = nil
    try(30) do
      pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
      expect(pipeline).to_not be_nil
    end
    expect(pipeline.config_str).to eq(pipeline_config.config_string)
    expect(agent.running_pipelines.keys.map(&:to_s)).to include(pipeline_config.pipeline_id.to_s)
  end

  match_when_negated do |agent|
    pipeline = nil
    try(30) do
      pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
      expect(pipeline).to be_nil
    end
  end
end

RSpec::Matchers.define :have_stopped_pipeline? do |pipeline_config|
  match do |agent|
    pipeline = nil
    try(30) do
      pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
      expect(pipeline).to_not be_nil
    end
    # either the pipeline_id is not in the running pipelines OR it is but have different configurations
    expect(!agent.running_pipelines.keys.map(&:to_s).include?(pipeline_config.pipeline_id.to_s) || pipeline.config_str != pipeline_config.config_string).to be_truthy
  end

  match_when_negated do
    raise "Not implemented"
  end
end

RSpec::Matchers.define :have_running_pipeline? do |pipeline_config|
  match do |agent|
    pipeline = nil
    try(30) do
      pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
      expect(pipeline).to_not be_nil
      expect(pipeline.running?).to be_truthy
    end
    expect(pipeline.config_str).to eq(pipeline_config.config_string)
    expect(agent.running_pipelines.keys.map(&:to_s) + agent.loading_pipelines.keys.map(&:to_s)).to include(pipeline_config.pipeline_id.to_s)
  end

  failure_message do |agent|
    pipeline = agent.get_pipeline(pipeline_config.pipeline_id)

    if pipeline.nil?
      "Expected pipeline to exist and running, be we cannot find '#{pipeline_config.pipeline_id.to_s}' in the running pipelines '#{agent.running_pipelines.keys.join(",")}'"
    else
      if !pipeline.running?
        "Found '#{pipeline_config.pipeline_id.to_s}' in the list of pipelines but its not running"
      elsif pipeline.config_str != pipeline_config.config_string
        "Found '#{pipeline_config.pipeline_id.to_s}' in the list of pipelines and running, but the config_string doesn't match,\nExpected:\n#{pipeline_config.config_string}\n\ngot:\n#{pipeline.config_str}"
      elsif agent.running_pipelines.keys.map(&:to_s).include?(pipeline_config.pipeline_id.to_s)
        "Found '#{pipeline_config.pipeline_id.to_s}' in running but not included in the list of agent.running_pipelines or agent.loading_pipelines"
      else
        "Unrecognized error condition, probably you missed to track properly a newly added expect in :have_running_pipeline?"
      end
    end
  end

  match_when_negated do
    raise "Not implemented"
  end
end

RSpec::Matchers.define :be_a_successful_converge do
  match do |converge_results|
    converge_results.success?
  end

  failure_message do |converge_results|
    "Expected all actions to be successful:
    #{converge_results.failed_actions.collect { |action, result| "pipeline_id: #{action.pipeline_id}, message: #{result.message}"}.join("\n")}"
  end

  failure_message_when_negated do |converge_results|
    "Expected all actions to failed:
    #{converge_results.successful_actions.collect { |action, result| "pipeline_id: #{action.pipeline_id}"}.join("\n")}"
  end
end

RSpec::Matchers.define :be_a_successful_action do
  match do |pipeline_action|
    case pipeline_action
    when LogStash::ConvergeResult::ActionResult
      return pipeline_action.successful?
    when TrueClass
      return true
    when FalseClass
      return false
    else
      raise "Incompatible class type of: #{pipeline_action.class}, Expected `Boolean` or `LogStash::ConvergeResult::ActionResult`"
    end
  end
end

RSpec::Matchers.define :be_a_source_with_metadata do |protocol, id, text = nil|
  match do |actual|
   expect(actual.protocol).to eq(protocol)
   expect(actual.id).to eq(id)
   expect(actual.text).to match(text) unless text.nil?
  end
end

RSpec::Matchers.define :be_a_config_loading_error_hash do |regex|
  match do |hash|
    expect(hash).to include(:error)
    error = hash[:error]
    expect(error).to be_a(LogStash::ConfigLoadingError)
    expect(error.message).to match(regex)
  end

  match_when_negated do
    raise "Not implemented"
  end
end
