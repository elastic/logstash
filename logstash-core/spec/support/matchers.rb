# encoding: utf-8
require "rspec"
require "rspec/expectations"
require "logstash/config/pipeline_config"
require "stud/try"

RSpec::Matchers.define :be_a_metric_event do |namespace, type, *args|
  match do
    namespace == Array(actual[0]).concat(Array(actual[1])) &&
      type == actual[2] &&
      args == actual[3..-1]
  end
end

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
      klass_name = "LogStash::PipelineAction::#{i.first.capitalize}"
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
    pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
    expect(pipeline).to_not be_nil
    expect(pipeline.config_str).to eq(pipeline_config.config_string)
  end

  match_when_negated do |agent|
    pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
    pipeline.nil? || pipeline.config_str != pipeline_config.config_string
  end
end

RSpec::Matchers.define :have_running_pipeline? do |pipeline_config|
  match do |agent|
    Stud.try(10.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      pipeline = agent.get_pipeline(pipeline_config.pipeline_id)
      expect(pipeline).to_not be_nil
      expect(pipeline.config_str).to eq(pipeline_config.config_string)
      expect(pipeline.running?).to be_truthy
    end
  end

  failure_message do |agent|
    pipeline = agent.get_pipeline(pipeline_config.pipeline_id)

    if pipeline.nil?
      "Expected pipeline to exist and running, be we cannot find `#{pipeline_config.pipeline_id}` in the running pipelines `#{agent.pipelines.keys.join(",")}`"
      else
        if pipeline.running? == false
          "Found `#{pipeline_config.pipeline_id}` in the list of pipelines but its not running"
        elsif pipeline.config_str != pipeline_config.config_string
          "Found `#{pipeline_config.pipeline_id}` in the list of pipelines and running, but the config_string doesn't match,
Expected:
#{pipeline_config.config_string}

got:
#{pipeline.config_str}"
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

