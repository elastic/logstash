# encoding: utf-8
require "rspec"
require "rspec/expectations"

RSpec::Matchers.define :be_a_metric_event do |namespace, type, *args|
  match do
    namespace == actual[0] << actual[1] && 
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
    expected.instance_methods - actual.instance_methods 
  end

  def all_instance_methods_implemented?
    missing_methods.empty?
  end

  failure_message do
    "Expecting `#{expected}` to implements instance methods of `#{actual}`, missing methods: #{missing_methods.join(",")}"
  end
end
