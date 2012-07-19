require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/filterworker"
require "logstash/filters"
require "logstash/filters/split"
require "logstash/event"

describe LogStash::Filters::Split do
  before do
    @typename = "split-test"
  end

  # TODO(sissel): Refactor this into a reusable method.
  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if !cfg[key].is_a?(Array)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Split.new(cfg)
  end

  test "default behavior" do
    config "type" => @typename

    inputs = [
      "one\ntwo",
      "\nthree\nfour\n",
      "five"
    ]

    expected_outputs = [
      "one",
      "two",
      "three",
      "four",
      "five"
    ]
         
    outputs = []

    @filter_worker = LogStash::FilterWorker.new([@filter], nil, outputs)
    @filter_worker.logger = LogStash::Logger.new(STDERR)
    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter_worker.filter(event)
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual.message)
    end
  end # test default behavior
  
  test "when field is set" do
    config "type" => @typename, "field" => "@source"

    inputs = [
      "one\ntwo",
      "\nthree\nfour\n",
      "five"
    ]

    expected_outputs = [
      "one",
      "two",
      "three",
      "four",
      "five"
    ]
         
    outputs = []

    @filter_worker = LogStash::FilterWorker.new([@filter], nil, outputs)
    @filter_worker.logger = LogStash::Logger.new(STDERR)
    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = "foo"
      event.source = input
      @filter_worker.filter(event)
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual.source)
    end
  end # test when field is set

  test "when terminator is set" do
    config "type" => @typename, "terminator" => "o"

    inputs = [
      "hello world",
      "one + two",
      "is four",
      "five"
    ]

    expected_outputs = [
      "hell",
      " w",
      "rld",
      "ne + tw",
      "is f",
      "ur",
      "five"
    ]
         
    outputs = []

    @filter_worker = LogStash::FilterWorker.new([@filter], nil, outputs)
    @filter_worker.logger = LogStash::Logger.new(STDERR)
    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter_worker.filter(event)
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual.message)
    end
  end # test when terminator is set

end # tests for LogStash::Filters::Split
