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

    th = Thread.current
    input do |plugins|
      relp = plugins.first

      #Define test output
      sequence = 0
      output = Shiftback.new do |event|
        sequence += 1
        relp.teardown if sequence == event_count
        begin
          insist { event.message } == "Hello"
        rescue  Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
      end

      #Run input in a separate thread
      relp.register
      thread = Thread.new(relp, output) do |*args|
        relp.run(output)
      end

      #Send events from clients
      client = RelpClient.new("0.0.0.0", port, ["syslog"])
      event_count.times do |value|
        client.syslog_write("Hello")
      end
      #Do not call client.close as the connection termination will be
      #initiated by the relp server
      #wait for input termination
      thread.join()
    end # input
  end
  describe "Two client connection" do
    event_count = 100
    port = 5511
    config <<-CONFIG
    input {
      relp {
        type => "blah"
        port => #{port}
      }
    }
    CONFIG

    th = Thread.current
    input do |plugins|
      sequence = 0
      relp = plugins.first
      output = Shiftback.new do |event|
        sequence += 1
        relp.teardown if sequence == event_count
        begin
          insist { event.message } == "Hello"
        rescue  Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
      end

      relp.register
      #Run input in a separate thread
      thread = Thread.new(relp, output) do |*args|
        relp.run(output)
      end

      #Send events from clients sockets
      client = RelpClient.new("0.0.0.0", port, ["syslog"])
      client2 = RelpClient.new("0.0.0.0", port, ["syslog"])
      event_count.times do |value|
        client.syslog_write("Hello")
        client2.syslog_write("Hello")
      end
      #Do not call client.close as the connection termination will be
      #initiated by the relp server
      
      #wait for input termination
      thread.join
    end # input
  end
end
