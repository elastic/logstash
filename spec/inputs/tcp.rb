# coding: utf-8
require "test_utils"
require "socket"

describe "inputs/tcp", :socket => true do
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
      socket.puts(data.to_json)
      socket.close

      event = queue.pop
      insist { event["hello"] } == data["hello"]
      insist { event["foo"] } == data["foo"]
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
      socket.puts(data.to_json)
      socket.close

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
        socket.puts(data.to_json+"\n")
      end # do
      socket.close

      (1..5).each do |idx|
        event = queue.pop
        insist { event["hello"] } == data["hello"]
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["idx"] } == idx
      end # do
    end # input
  end # describe
end



