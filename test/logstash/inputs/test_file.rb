#!/usr/bin/env ruby
require 'rubygems'
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"
require "test/unit"
require "tempfile"
require "logstash/testcase"
require "logstash/agent"


# TODO(sissel): refactor this so we can more easily specify tests.
class TestInputFile < LogStash::TestCase
  def em_setup
    @tmpfile = Tempfile.new(self.class.name)

    config = {
      "inputs" => {
        @type => [
          "file://#{@tmpfile.path}"
        ],
      },
      "outputs" => [
        "internal:///"
      ]
    } # config

    super(config)
  end

  def test_simple
    data = [ "hello", "world", "hello world 1 2 3 4", "1", "2", "3", "4", "5" ]
    remaining = data.size
    EventMachine.run do
      em_setup
      expect_data = data.clone
      @output.subscribe do |event|
        expect_message = expect_data.shift
        assert_equal(expect_message, event.message)
        assert_equal("file://#{@hostname}#{@tmpfile.path}", event.source)
        assert_equal(@type, event.type, "type")
        assert_equal([], event.tags, "tags should be empty")

        # Done testing if we run out of data.
        @agent.stop if expect_data.size == 0
      end

      # Write to the file periodically
      timer = EM::PeriodicTimer.new(0.2) do
        out = data.shift((rand * 3).to_i + 1).join("\n")
        @tmpfile.puts out
        @tmpfile.flush
        timer.cancel if data.length == 0
      end
    end
  end # def test_simple
end # class TestInputFile

