require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/filters"
require "logstash/filters/multiline"
require "logstash/event"

describe LogStash::Filters::Multiline do
  before do
    @typename = "multiline-test"
  end

  # TODO(sissel): Refactor this into a reusable method.
  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if !cfg[key].is_a?(Array)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Multiline.new(cfg)
    @filter.register
  end

  test "using 'next' mode" do
    config "pattern" => "\\.\\.\\.$", "what" => "next"

    inputs = [
      "hello world ...",
      "and more!",
      "one",
      "two...",
      "two again",
    ]

    expected_outputs = [
      "hello world ...\nand more!",
      "one",
      "two...\ntwo again",
    ]
         
    outputs = []

    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter.filter(event)
      if !event.cancelled?
        outputs << event.message
      end
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end # test with what => 'next'
  
  test "using 'previous' mode" do
    config "pattern" => "^\\s", "what" => "previous"

    inputs = [
      "hello world ...",
      "   and more!",
      "one",
      "two",
      "   two 1",
      "   two 2",
      "   two 3",
      "three",
    ]

    expected_outputs = [
      "hello world ...\n   and more!",
      "one",
      "two\n   two 1\n   two 2\n   two 3",
      "three"
    ]
         
    outputs = []

    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter.filter(event)
      if !event.cancelled?
        outputs << event.message
      end
    end
    last = @filter.flush("unknown.#{@typename}")
    if last
      outputs << last.message
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end # test using 'previous'

  test "with negate => true" do
    @logger = LogStash::Logger.new(STDERR)
    config "pattern" => "^\\S", "what" => "previous", "negate" => "true"

    inputs = [
      "hello world ...",
      "   and more!",
      "one",
      "two",
      "   two 1",
      "   two 2",
      "   two 3",
      "three",
    ]

    expected_outputs = [
      "hello world ...\n   and more!",
      "one",
      "two\n   two 1\n   two 2\n   two 3",
      "three"
    ]

    outputs = []

    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter.filter(event)
      if !event.cancelled?
        outputs << event.message
      end
    end
    last = @filter.flush("unknown.#{@typename}")
    if last
      outputs << last.message
    end
    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end # negate tests

  test "with negate => 'false'"  do
    @logger = LogStash::Logger.new(STDERR)
    config "pattern" => "^\\s", "what" => "previous", "negate" => "false"

    inputs = [
      "hello world ...",
      "   and more!",
      "one",
      "two",
      "   two 1",
      "   two 2",
      "   two 3",
      "three",
    ]

    expected_outputs = [
      "hello world ...\n   and more!",
      "one",
      "two\n   two 1\n   two 2\n   two 3",
      "three"
    ]

    outputs = []

    inputs.each do |input|
      event = LogStash::Event.new
      event.type = @typename
      event.message = input
      @filter.filter(event)
      if !event.cancelled?
        outputs << event.message
      end
    end
    last = @filter.flush("unknown.#{@typename}")
    if last
      outputs << last.message
    end
    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end # negate false

  test "with custom stream identity" do
    config "pattern" => ".*", "what" => "next",
      "stream_identity" => "%{key}"

    inputs = [
      "one",
      "two",
      "one",
      "two",
      "one",
    ]

    expected_outputs = [
      "one\none\none",
      "two\ntwo",
    ]
         
    outputs = []

    inputs.each_with_index do |input, i|
      event = LogStash::Event.new
      event.type = @typename
      # even/odd keying to fake multiple streams.
      event["key"] = ["odd", "even"][i % 2]
      event.message = input
      @filter.filter(event)
      if !event.cancelled?
        outputs << event.message
      end
    end
    outputs << @filter.flush("odd").message
    outputs << @filter.flush("even").message
    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end
end # tests for LogStash::Filters::Multiline
