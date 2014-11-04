# coding: utf-8
require "spec_helper"
require "socket"
require "logstash/inputs/syslog"
require "logstash/event"

describe "inputs/syslog" do
  

  it "should properly handle priority, severity and facilities", :socket => true do
    port = 5511
    event_count = 10

    config <<-CONFIG
      input {
        syslog {
          type => "blah"
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      event_count.times do |i|
        socket.puts("<164>Oct 26 15:19:25 1.2.3.4 %ASA-4-106023: Deny udp src DRAC:10.1.2.3/43434 dst outside:192.168.0.1/53 by access-group \"acl_drac\" [0x0, 0x0]")
      end
      socket.close

      events = event_count.times.collect { queue.pop }

      insist { events.length } == event_count
      event_count.times do |i|
        insist { events[i]["priority"] } == 164
        insist { events[i]["severity"] } == 4
        insist { events[i]["facility"] } == 20
      end
    end
  end

  it "should add unique tag when grok parsing fails with live syslog input", :socket => true do
    port = 5511
    event_count = 10

    config <<-CONFIG
      input {
        syslog {
          type => "blah"
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      event_count.times do |i|
        socket.puts("message which causes the a grok parse failure")
      end
      socket.close

      events = event_count.times.collect { queue.pop }

      insist { events.length } == event_count
      event_count.times do |i|
        insist { events[i]["tags"] } == ["_grokparsefailure_sysloginputplugin"]
      end
    end
  end

  it "should add unique tag when grok parsing fails" do
    input = LogStash::Inputs::Syslog.new({})
    input.register

    # event which is not syslog should have a new tag
    event = LogStash::Event.new({ "message" => "hello world, this is not syslog RFC3164" })
    input.syslog_relay(event)
    insist { event["tags"] } ==  ["_grokparsefailure_sysloginput"]

    syslog_event = LogStash::Event.new({ "message" => "<164>Oct 26 15:19:25 1.2.3.4 %ASA-4-106023: Deny udp src DRAC:10.1.2.3/43434" })
    input.syslog_relay(syslog_event)
    insist { syslog_event["priority"] } ==  164
    insist { syslog_event["severity"] } ==  4
    insist { syslog_event["tags"] } ==  nil
  end

end
