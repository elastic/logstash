# encoding: utf-8
require "rspec"
require "rspec/expectations"

RSpec::Matchers.define :be_a_metric_event do |type, key, value|
  match do
    actual.first == type &&
      actual[1].kind_of?(Time) &&
      actual[2] == key &&
      actual.last == value
  end
end

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

  failure_message_for_should do
    "Expecting `#{expected}` to implements instance methods of `#{actual}`, missing methods: #{missing_methods.join(",")}"
  end
end
