# coding: utf-8
require "test_utils"
require "socket"
require "logstash/util/relp"

describe "inputs/relp" do
  extend LogStash::RSpec

  describe "Single client connection" do
    event_count = 10
    port = 5511
    config <<-CONFIG
    input {
      relp {
        type => "blah"
        port => #{port}
      }
    }
    CONFIG

    input do |pipeline, queue|
      th = Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      #Send events from clients
      client = RelpClient.new("0.0.0.0", port, ["syslog"])
      event_count.times do |value|
        client.syslog_write("Hello #{value}")
      end

      events = event_count.times.collect { queue.pop }
      event_count.times do |i|
        insist { events[i]["message"] } == "Hello #{i}"
      end

      pipeline.shutdown
      th.join
    end # input
  end
  describe "Two client connection" do
    event_count = 100
    port = 5512
    config <<-CONFIG
    input {
      relp {
        type => "blah"
        port => #{port}
      }
    }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      #Send events from clients sockets
      client = RelpClient.new("0.0.0.0", port, ["syslog"])
      client2 = RelpClient.new("0.0.0.0", port, ["syslog"])

      event_count.times do |value|
        client.syslog_write("Hello from client")
        client2.syslog_write("Hello from client 2")
      end

      events = (event_count*2).times.collect { queue.pop }
      insist { events.select{|event| event["message"]=="Hello from client" }.size } == event_count
      insist { events.select{|event| event["message"]=="Hello from client 2" }.size } == event_count
    end # input
  end
end
