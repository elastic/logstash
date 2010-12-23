#!/usr/bin/env ruby
require 'rubygems'
$:.unshift File.dirname(__FILE__) + "/../../lib"
require "test/unit"
require "logstash"
require "logstash/filters"
require "logstash/event"
require "tempfile"
require "socket"


# TODO(sissel): refactor this so we can more easily specify tests.
class TestInputFile < Test::Unit::TestCase
  def em_setup
    @tmpfile = Tempfile.new(self.class.name)
    @type = "default"
    @hostname = Socket.gethostname

    config = YAML.load <<-"YAML"
    inputs:
      #{@type}:
        - file://#{@tmpfile.path}
    outputs:
      - internal:///
    YAML

    @output = EventMachine::Channel.new
    @agent = LogStash::Agent.new(config)
    @agent.register
    @agent.outputs[0].callback do |event|
      @output.push(event)
    end
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
        a = data.shift((rand * 3).to_i + 1).join("\n")
        @tmpfile.puts a
        @tmpfile.flush
        timer.cancel if data.length == 0
      end
    end
  end # def test_simple
end # class TestInputFile

