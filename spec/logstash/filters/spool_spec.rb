require "spec_helper"
require "logstash/filters/spool"

#NOOP filter is perfect for testing Filters::Base features with minimal overhead
describe LogStash::Filters::Spool do

  # spool test are really flush tests. spool does nothing more than waiting for flush to be called.

  describe "flush one event" do
    config <<-CONFIG
    filter {
      spool { }
    }
    CONFIG

    sample "foo" do
      insist { subject["message"] } == "foo"
    end
  end

  describe "spooling multiple events" do
    config <<-CONFIG
    filter {
      spool { }
    }
    CONFIG

    sample ["foo", "bar"] do
      insist { subject[0]["message"] } == "foo"
      insist { subject[1]["message"] } == "bar"
    end
  end

  describe "spooling events through conditionals" do
    config <<-CONFIG
    filter {
      spool { }
      if [message] == "foo" {
        mutate { add_field => { "cond1" => "true" } }
      } else {
        mutate { add_field => { "cond2" => "true" } }
      }
      mutate { add_field => { "last" => "true" } }
    }
    CONFIG

    sample ["foo", "bar"] do
      insist { subject[0]["message"] } == "foo"
      insist { subject[0]["cond1"] } == "true"
      insist { subject[0]["cond2"] } == nil
      insist { subject[0]["last"] } == "true"

      insist { subject[1]["message"] } == "bar"
      insist { subject[1]["cond1"] } == nil
      insist { subject[1]["cond2"] } == "true"
      insist { subject[1]["last"] } == "true"
    end
  end

 describe "spooling eventS with conditionals" do
    config <<-CONFIG
    filter {
      mutate { add_field => { "first" => "true" } }
      if [message] == "foo" {
        spool { }
      } else {
        mutate { add_field => { "cond2" => "true" } }
      }
      mutate { add_field => { "last" => "true" } }
    }
    CONFIG

    sample ["foo", "bar"] do
      # here received events will be reversed since the spooled one will be flushed last, at shutdown

      insist { subject[0]["message"] } == "bar"
      insist { subject[0]["first"] } == "true"
      insist { subject[0]["cond2"] } == "true"
      insist { subject[0]["last"] } == "true"

      insist { subject[1]["message"] } == "foo"
      insist { subject[1]["first"] } == "true"
      insist { subject[1]["cond2"] } == nil
      insist { subject[1]["last"] } == "true"
    end
  end

end
