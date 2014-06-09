# coding: utf-8
require "test_utils"
require "socket"
require "msgpack"

describe "inputs/fluent" do
  extend LogStash::RSpec

  describe "read event" do
    port = 5511
    config <<-CONFIG
      input {
        fluent {
          port => #{port}
        }
      }
    CONFIG

    data = MessagePack.pack([
      "syslog",
      MessagePack.pack([0, {"message" => "Hello World"}]).force_encoding("UTF-8") +
      MessagePack.pack([1, {"message" => "Bye World"}]).force_encoding("UTF-8")
    ])

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 until pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.puts(data)
      socket.close

      events = 2.times.collect { queue.pop }

      insist { events[0]["@timestamp"] } == Time.at(0).utc
      insist { events[0]["message"] } == "Hello World"
      insist { events[0]["tags"] } == ["syslog"]

      insist { events[1]["@timestamp"] } == Time.at(1).utc
      insist { events[1]["message"] } == "Bye World"
      insist { events[1]["tags"] } == ["syslog"]
    end # input
  end

  describe "responds to tcp heartbeats" do
    port = 5512
    config <<-CONFIG
      input {
        fluent {
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 until pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.close
    end # input
  end

  describe "responds to udp heartbeats" do
    port = 5513
    config <<-CONFIG
      input {
        fluent {
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 until pipeline.ready?

      socket = Stud.try(5.times) { UDPSocket.new(Socket::AF_INET) }
      socket.send("\0", 0, "127.0.0.1", port)

      Stud.try(5.times) {
        IO.select([socket], nil, nil, 0.1)
        data, _ = socket.recvfrom_nonblock(128)
        insist { data } == "\0"
      }

      socket.close
    end # input
  end

  describe "explicit codec does not have any effect" do
    port = 5514
    config <<-CONFIG
      input {
        fluent {
          port => #{port}
          codec => json
        }
      }
    CONFIG

    data = MessagePack.pack([
      "syslog", 
      MessagePack.pack([0, {"message" => "Hello World"}]).force_encoding("UTF-8")
    ])
    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 until pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.puts(data)
      socket.close

      event = queue.pop

      insist { event["@timestamp"] } == Time.at(0).utc
      insist { event["message"] } == "Hello World"
      insist { event["tags"] } == ["syslog"]
    end # input
  end

  describe "ignore fluent\"s tag" do
    port = 5515
    config <<-CONFIG
    input {
      fluent {
        port => #{port}
        ignore_tag => true
      }
    }
    CONFIG

    data = MessagePack.pack([
      "syslog", 
      MessagePack.pack([0, {"message" => "Hello World"}]).force_encoding("UTF-8")
    ])
    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 until pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.puts(data)
      socket.close

      event = queue.pop

      insist { event["@timestamp"] } == Time.at(0).utc
      insist { event["message"] } == "Hello World"
      insist { event["tags"] } == nil
    end # input
  end

end



