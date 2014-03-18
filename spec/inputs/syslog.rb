# coding: utf-8
require "test_utils"
require "socket"

describe "inputs/syslog", :socket => true do
  extend LogStash::RSpec

  describe "properly handles priority, severity and facilities" do
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
      event_count.times do |i|
        insist { events[i]["priority"] } == 164
        insist { events[i]["severity"] } == 4
        insist { events[i]["facility"] } == 20
      end
    end
  end
end

