# encoding: utf-8

# run with: ruby exploit_beats_input.rb host port
# where host is where Logstash is running and port is the beats input bound port
# this will trigger a warn log entry with the jndi uri, causing a lookup to 127.0.0.1:1389 on Logstash != 6.8.21 and 7.16.1
# open `nc -l 1389` to observe the connection
require "socket"
require "thread"
require "zlib"
require "json"
require "openssl"

Thread.abort_on_exception = true
HOST="127.0.0.1"
PORT=3333
CLIENT_CERT="/Users/andrea/workspace/certificates/client_from_root.crt"
CLIENT_KEY="/Users/andrea/workspace/certificates/client_from_root.key.pkcs8"

module Lumberjack
  SEQUENCE_MAX = (2**32-1).freeze

  class Client
    def initialize
      @sequence = 0
      @socket = connect
    end



    private
    def connect
      #puts "DNADBG>> connect starts"
      socket = TCPSocket.new(HOST, PORT)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(CLIENT_CERT))
      ctx.key = OpenSSL::PKey::RSA.new(File.read(CLIENT_KEY))
      ctx.ssl_version = :TLSv1_2

      #puts "DNADBG>> connect after context creation"

      # Wrap the socket with SSL/TLS
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
      ssl_socket.sync_close = true
      #puts "DNADBG>> connect after ssl socket creation"
      ssl_socket.connect
      #puts "DNADBG>> connect after connect"
      ssl_socket
    end

    public
    def write(elements, opts={})
      elements = [elements] if elements.is_a?(Hash)
      send_window_size(elements.size)

      payload = elements.map { |element| JsonEncoder.to_frame(element, inc) }.join
      send_payload(payload)
    end

    private
    def inc
      @sequence = 0 if @sequence + 1 > Lumberjack::SEQUENCE_MAX
      @sequence = @sequence + 1
    end

    private
    def send_window_size(size)
      @socket.syswrite(["2", "W", size].pack("AAN"))
    end

    private
    def send_payload(payload)
      payload_size = payload.size
      written = 0
      while written < payload_size
        written += @socket.syswrite(payload[written..-1])
      end
    end

    public 
    def send_raw(payload)
      send_payload(payload)
    end

    public
    def close
      @socket.close
    end
  end

  module JsonEncoder
    def self.to_frame(hash, sequence)
      json = hash.to_json
      json_length = json.bytesize
      pack = "AANNA#{json_length}"
      frame = ["2", "J", sequence, json_length, json]
      frame.pack(pack)
    end
  end

end

client_count = 24 #cores * 2 = event loops threads
#message = 'a'*4*16*1024

mb = 1024 * 1024
kb = 1024
total_traffic_for_connection = 40 * mb
message_size = 16 * kb 

message = 'a' * message_size + "\n"
repetitions = total_traffic_for_connection / message_size


puts "Connecting #{client_count} clients"
clients = client_count.times.map { Lumberjack::Client.new }
puts "Connected #{client_count} clients"
puts "Writing approximately #{(client_count * repetitions * message.size)/1024.0/1024.0}Mib across #{client_count} clients (message size: #{message_size} Kb)"
start = Time.now()
sent_messages = java.util.concurrent.atomic.AtomicLong.new(0)
# Case: one thread per connection sends a lot of data.
threads = client_count.times.map do |i|
  Thread.new(i) do |i|
    client = clients[i]
    # keep message size above 16k, requiring two TLS records
#    data = [ { "message" => message } ]
    repetitions.times do 
#      client.write(data) # this convert JSON to bytes
      client.send_raw(message)
      sent_messages.incrementAndGet
#      sleep 1*rand
    end
    client.close
  end
end

# Case: some threads  creates a lots of connections.
#count_connections_created = java.util.concurrent.atomic.AtomicLong.new(0)
#clients = []
#threads = 12.times.map do |thread_num|
#  Thread.new(thread_num) do |i|
#    3000.times do |th_conn_counter|
#      begin
#        client = Lumberjack::Client.new
#        client.send_raw(message)
#      rescue => e
#        puts "Reached error creating connection, thread: #{thread_num} conn counter: #{th_conn_counter} #{e.message}"
#        exit 1
#      end  
#      clients << client
#      count_connections_created.incrementAndGet
#    end
#  end
#end

threads.each(&:join)

#puts "Connections created #{count_connections_created.get()}"
#clients.each { |client| client.close }

puts "Done in #{Time.now() - start} seconds"

global_speed = sent_messages.get / (Time.now() - start)
puts "Average evts(#{message_size}Kb)/sec: #{global_speed}"