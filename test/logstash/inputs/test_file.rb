#!/usr/bin/env ruby
require 'rubygems'
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "tempfile"
require "thread"
require "logstash/loadlibs"
require "logstash/agent"
require "logstash/logging"
require "logstash/util"
require "socket"

class TestInputFile < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile.new(self.class.name)
    @hostname = Socket.gethostname
    @type = "logstash-test"

    @agent = LogStash::Agent.new
    config = LogStash::Config::File.new(path=nil, string=<<-CONFIG)
      input {
        file {
          path => "#{@tmpfile.path}"
          type => "#{@type}"
        }
      }

      output {
        internal { }
      }
    CONFIG
    
    waitqueue = Queue.new

    Thread.new do
      @agent.run_with_config(config) do
        waitqueue << :ready
      end
    end

    # Wait for the agent to be ready.
    waitqueue.pop
    @output = @agent.outputs.first
  end # def setup

  def test_simple
    data = [ "hello", "world", "hello world 1 2 3 4", "1", "2", "3", "4", "5" ]
    remaining = data.size
    expect_data = data.clone

    queue = Queue.new
    @output.subscribe do |event|
      queue << event
    end

    # Write to the file periodically
    Thread.new do
      LogStash::Util.set_thread_name("#{__FILE__} - periodic writer")
      loop do
        out = data.shift((rand * 3).to_i + 1).join("\n")
        @tmpfile.puts out
        @tmpfile.flush
        break if data.length == 0
      end # loop
    end # timer thread

    loop do
      event = queue.pop
      expect_message = expect_data.shift
      assert_equal(expect_message, event.message)
      assert_equal("file://#{@hostname}#{@tmpfile.path}", event.source)
      assert_equal(@type, event.type, "type")
      assert_equal([], event.tags, "tags should be empty")

      # Done testing if we run out of data.
      if expect_data.size == 0
        @agent.stop 
        break
      end
    end
  end # def test_simple
end # class TestInputFile

