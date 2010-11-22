#!/usr/bin/env ruby
$: << "lib"

require "rubygems"
require "logstash/agent"
require "yaml"

collector_config = YAML.load <<"YAML"
---
inputs:
  foo:
  - internal:///
outputs:
- amqp://localhost/topic/logstash/testing
YAML

receiver_config = YAML.load <<"YAML"
---
inputs:
  foo:
  - amqp://localhost/topic/logstash/testing
outputs:
- internal:///
YAML

collector_agent = LogStash::Agent.new(collector_config)
receiver_agent = LogStash::Agent.new(receiver_config)

data = ["hello world", "foo", "bar"]

EventMachine::run do
  receiver_agent.register
  collector_agent.register

  EM::next_tick do
    # Register output callback on the receiver
    receiver_agent.outputs\
        .find { |o| o.is_a?(LogStash::Outputs::Internal) }\
        .callback do |event|
      puts event
      #puts expect.first == event.message
      #expect.shift
      #agent.stop
    end

    EM::next_tick do
      # Send input to the collector
      expect = data.clone
      input = collector_agent.inputs\
        .find { |i| i.is_a?(LogStash::Inputs::Internal) }
      channel = input.channel
      data.each { |message| channel.push(message) }
    end
  end
end

