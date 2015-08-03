# coding: utf-8
require "test_utils"
require "socket"
require "timeout"
require "logstash/json"

describe "inputs/tcp" do
  extend LogStash::RSpec

  describe "read plain with unicode" do
    event_count = 10
    port = 5511
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      event_count.times do |i|
        # unicode smiley for testing unicode support!
        socket.puts("#{i} ☹")
      end
      socket.close

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < event_count}

      events = event_count.times.collect { queue.pop }
      event_count.times do |i|
        insist { events[i]["message"] } == "#{i} ☹"
      end
    end # input
  end

  describe "read events with plain codec and ISO-8859-1 charset" do
    port = 5513
    charset = "ISO-8859-1"
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
          codec => plain { charset => "#{charset}" }
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      text = "\xA3" # the £ symbol in ISO-8859-1 aka Latin-1
      text.force_encoding("ISO-8859-1")
      socket.puts(text)
      socket.close

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < 1}

      event = queue.pop
      # Make sure the 0xA3 latin-1 code converts correctly to UTF-8.
      pending("charset conv broken") do
        insist { event["message"].size } == 1
        insist { event["message"].bytesize } == 2
        insist { event["message"] } == "£"
      end
    end # input
  end

  describe "read events with json codec" do
    port = 5514
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
          codec => json
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      data = {
        "hello" => "world",
        "foo" => [1,2,3],
        "baz" => { "1" => "2" },
        "host" => "example host"
      }

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.puts(LogStash::Json.dump(data))
      socket.close

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < 1}

      event = queue.pop
      insist { event["hello"] } == data["hello"]
      insist { event["foo"].to_a } == data["foo"] # to_a to cast Java ArrayList produced by JrJackson
      insist { event["baz"] } == data["baz"]

      # Make sure the tcp input, w/ json codec, uses the event's 'host' value,
      # if present, instead of providing its own
      insist { event["host"] } == data["host"]
    end # input
  end

  describe "read events with json codec (testing 'host' handling)" do
    port = 5514
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
          codec => json
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      data = {
        "hello" => "world"
      }

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      socket.puts(LogStash::Json.dump(data))
      socket.close

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < 1}

      event = queue.pop
      insist { event["hello"] } == data["hello"]
      insist { event }.include?("host")
    end # input
  end

  describe "read events with json_lines codec" do
    port = 5515
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
          codec => json_lines
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      data = {
        "hello" => "world",
        "foo" => [1,2,3],
        "baz" => { "1" => "2" },
        "idx" => 0
      }

      socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
      (1..5).each do |idx|
        data["idx"] = idx
        socket.puts(LogStash::Json.dump(data) + "\n")
      end # do
      socket.close

      (1..5).each do |idx|
        event = queue.pop
        insist { event["hello"] } == data["hello"]
        insist { event["foo"].to_a } == data["foo"] # to_a to cast Java ArrayList produced by JrJackson
        insist { event["baz"] } == data["baz"]
        insist { event["idx"] } == idx
      end # do
    end # input
  end # describe

  describe "one message per connection" do
    event_count = 10
    port = 5515
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      event_count.times do |i|
        socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
        socket.puts("#{i}")
        socket.flush
        socket.close
      end

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < event_count}

      # since each message is sent on its own tcp connection & thread, exact receiving order cannot be garanteed
      events = event_count.times.collect{queue.pop}.sort_by{|event| event["message"]}

      event_count.times do |i|
        insist { events[i]["message"] } == "#{i}"
      end
    end # input
  end

  describe "connection threads are cleaned up when connection is closed" do
    event_count = 10
    port = 5515
    config <<-CONFIG
      input {
        tcp {
          port => #{port}
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      inputs = pipeline.instance_variable_get("@inputs")
      insist { inputs.size } == 1

      sockets = event_count.times.map do |i|
        socket = Stud.try(5.times) { TCPSocket.new("127.0.0.1", port) }
        socket.puts("#{i}")
        socket.flush
        socket
      end

      # wait till all events have been processed
      Timeout.timeout(1) {sleep 0.1 while queue.size < event_count}

      # we should have "event_count" pending threads since sockets were not closed yet
      client_threads = inputs[0].instance_variable_get("@client_threads")
      insist { client_threads.size } == event_count

      # close all sockets and make sure there is not more pending threads
      sockets.each{|socket| socket.close}
      Timeout.timeout(1) {sleep 0.1 while client_threads.size > 0}
      insist { client_threads.size } == 0 # this check is actually useless per previous line

    end # input
  end
end



