#!/usr/bin/env ruby
#
# How to trigger the 'evil ip' message:
# % logger -t "pantscon" "naughty host 14.33.24.55 $RANDOM"

require "rubygems"
require "eventmachine"
require "lib/components/agent"
require "ap"

class MyAgent < LogStash::Components::Agent
  def receive(event)
    filter(event)  # Invoke any filters

    return unless event["progname"][0] == "pantscon"
    return unless event.message =~ /naughty host/
    event["IP"].each do |ip|
      next unless ip.length > 0
      puts "Evil IP: #{ip}"
    end
  end # def receive
end # class MyAgent

# Read a local file, parse it, and react accordingly (see MyAgent#receive)
agent = MyAgent.new({
  "input" => [
    "/var/log/messages",
  ],
  "filter" => [ "grok" ],
})
agent.run

# Read messages that we expect to be parsed by another agent. Reads
# a particular AMQP topic for messages
#agent = MyAgent.new({
  #"input" => [
    #"amqp://localhost/topic/parsed",
  #]
#})
#agent.run
