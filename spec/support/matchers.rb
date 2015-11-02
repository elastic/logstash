# encoding: utf-8
RSpec::Matchers.define :be_a_metric_event do |type, key, value|
  match do |actual|
    actual.first == type &&
      actual[1].kind_of?(Time) &&
      actual[2] == key &&
      actual.last == value
  end
end

