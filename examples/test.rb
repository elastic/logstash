#!/usr/bin/env ruby

require "rubygems"
require "eventmachine"
require "lib/components/agent"
require "ap"

class MyAgent < LogStash::Components::Agent
  def initialize
    super({
        "input" => [
          "amqp://localhost/topic/parsed",
        ]
    })
  end # def initialize

  def receive(event)
    return unless event["progname"][0] == "pantscon"
    return unless event["message"] =~ /naughty host/
    event["IP"].each do |ip|
      next unless ip.length > 0
      puts "Evil IP: #{ip}"
    end
  end # def receive
end # class MyAgent

agent = MyAgent.new
agent.run
