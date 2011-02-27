require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"
require "test/unit"
require "logstash"
require "logstash/filters"
require "logstash/filters/multiline"
require "logstash/event"

class TestFilterMultiline < Test::Unit::TestCase
  def setup
    @filter = LogStash::Filters.from_name("multiline", {})
  end

  def test_name(name)
    @typename = name
  end

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

  def test_with_next
    test_name "with next"
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
  end # def test_with_next
  
  def test_with_previous
    test_name "with previous"
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
    last = @filter.flush("unknown", @typename)
    if last
      outputs << last.message
    end

    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end

  def test_with_negate_true
    @logger = LogStash::Logger.new(STDERR)
    test_name "with negate true"
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
    last = @filter.flush("unknown", @typename)
    if last
      outputs << last.message
    end
    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end

  def test_with_negate_false
    @logger = LogStash::Logger.new(STDERR)
    test_name "with negate true"
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
    last = @filter.flush("unknown", @typename)
    if last
      outputs << last.message
    end
    assert_equal(expected_outputs.length, outputs.length,
                 "Incorrect number of output events")
    expected_outputs.zip(outputs).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end
end
