# coding: utf-8
require "test_utils"
require "socket"

# Not sure why but each test need a different port
# TODO: timeout around the thread.join
describe "inputs/tcp" do
  extend LogStash::RSpec

  describe "read json_event" do

    event_count = 10
    port = 5511
    config <<-CONFIG
    input {
      tcp {
        type => "blah"
        port => #{port}
        format => "json_event"
      }
    }
    CONFIG

    th = Thread.current
    input do |plugins|
      sequence = 0
      tcp = plugins.first
      output = Shiftback.new do |event|
        sequence += 1
        tcp.teardown if sequence == event_count
        begin
          insist { event["sequence"] } == sequence -1
          insist { event["message"]} == "Hello ü Û"
          insist { event["message"].encoding } == Encoding.find("UTF-8")
        rescue Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
      end
      #Prepare input
      tcp.register
      #Run input in a separate thread
      thread = Thread.new(tcp, output) do |*args|
        tcp.run(output)
      end
      #Send events from clients sockets
      event_count.times do |value|
        client_socket = TCPSocket.new("0.0.0.0", port)
        event = LogStash::Event.new("@fields" => { "message" => "Hello ü Û", "sequence" => value })
        client_socket.puts event.to_json
        client_socket.close
        # micro sleep to ensure sequencing
        sleep(0.1)
      end
      #wait for input termination
      thread.join
    end # input
  end

  describe "read plain events with system defaults, should works on UTF-8 system" do
    event_count = 10
    port = 5512
    config <<-CONFIG
    input {
      tcp {
        type => "blah"
        port => #{port}
      }
    }
    CONFIG

    th = Thread.current
    input do |plugins|
      sequence = 0
      tcp = plugins.first
      output = Shiftback.new do |event|
        sequence += 1
        begin
          insist { event.message } == "Hello ü Û"
          insist { event.message.encoding } == Encoding.find("UTF-8")
        rescue Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
        if sequence == event_count
          tcp.teardown 
        end
      end

      tcp.register
      #Run input in a separate thread
      thread = Thread.new(tcp, output) do |*args|
        tcp.run(output)
      end
      #Send events from clients sockets
      event_count.times do |value|
        client_socket = TCPSocket.new("0.0.0.0", port)
        client_socket.write "Hello ü Û"
        client_socket.close
        # micro sleep to ensure sequencing
        sleep(0.1)
      end
      #wait for input termination
      puts "Waiting for tcp input thread to finish"
      thread.join
    end # input
  end

  describe "read plain events with UTF-8 like charset, to prove that something is wrong with previous failing test" do
    event_count = 10
    port = 5514
    config <<-CONFIG
    input {
      tcp {
        type => "blah"
        port => #{port}
        charset => "CP65001" #that's just an alias of UTF-8
      }
    }
    CONFIG

    th = Thread.current
    # Catch aborting reception threads
    input do |plugins|
      sequence = 0
      tcp = plugins.first
      output = Shiftback.new do |event|
        sequence += 1
        tcp.teardown if sequence == event_count
        begin
          insist { event.message } == "Hello ü Û"
          insist { event.message.encoding } == Encoding.find("UTF-8")
        rescue Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
      end

      tcp.register
      #Run input in a separate thread

      thread = Thread.new(tcp, output) do |*args|
        tcp.run(output)
      end
      #Send events from clients sockets
      event_count.times do |value|
        client_socket = TCPSocket.new("0.0.0.0", port)
        # puts "Encoding of client", client_socket.external_encoding, client_socket.internal_encoding
        client_socket.write "Hello ü Û"
        client_socket.close
        # micro sleep to ensure sequencing, TODO must think of a cleaner solution
        sleep(0.1)
      end
      #wait for input termination
      #TODO: timeout
      thread.join
    end # input
  end

  describe "read plain events with ISO-8859-1 charset" do
    event_count = 10
    port = 5513
    charset = "ISO-8859-1"
    config <<-CONFIG
    input {
      tcp {
        type => "blah"
        port => #{port}
        charset => "#{charset}"
      }
    }
    CONFIG

    th = Thread.current
    input do |plugins|
      sequence = 0
      tcp = plugins.first
      output = Shiftback.new do |event|
        sequence += 1
        tcp.teardown if sequence == event_count
        begin
          insist { event.message } == "Hello ü Û"
          insist { event.message.encoding } == Encoding.find("UTF-8")
        rescue Exception => failure
          # Get out of the threads nets
          th.raise failure
        end
      end

      tcp.register
      #Run input in a separate thread

      thread = Thread.new(tcp, output) do |*args|
        tcp.run(output)
      end
      #Send events from clients sockets
      event_count.times do |value|
        client_socket = TCPSocket.new("0.0.0.0", port)
        #Force client encoding
        client_socket.set_encoding(charset)
        client_socket.write "Hello ü Û"
        client_socket.close
        # micro sleep to ensure sequencing
        sleep(0.1)
      end
      #wait for input termination
      thread.join
    end # input
  end
end



