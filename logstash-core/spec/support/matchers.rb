# encoding: utf-8
require "rspec"
require "rspec/expectations"

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
