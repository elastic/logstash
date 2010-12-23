
require 'rubygems'
$:.unshift File.dirname(__FILE__) + "/../../lib"

require "test/unit"
require "socket"
require "logstash/namespace"
require "logstash/outputs/internal"
require "logstash/inputs/internal"

class LogStash::TestCase < Test::Unit::TestCase
  def setup
    super
    @type = "default"
    @hostname = Socket.gethostname
  end

  def em_setup(config = {})
    @agent = LogStash::Agent.new(config)
    @agent.register

    @output = EventMachine::Channel.new
    output = @agent.outputs.find { |o| o.is_a?(LogStash::Outputs::Internal) }
    
    if output
      output.callback do |event|
        @output.push(event)
      end
    end

    input = @agent.inputs.find { |o| o.is_a?(LogStash::Inputs::Internal) }
    @input = input.channel if input
  end # def em_setup

  # We have to include at least one test here, otherwise Test::Unit barfs about
  # not tests for this class, even though it's just a superclass for real test
  # cases.
  def test_ok; end
end # class LogStash::TestCase
