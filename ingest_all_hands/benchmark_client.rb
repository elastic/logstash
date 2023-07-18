# encoding: utf-8

require "socket"
require "thread"
require "zlib"
require "json"
require "openssl"
require 'optparse'

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
      socket = TCPSocket.new(HOST, PORT)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(CLIENT_CERT))
      ctx.key = OpenSSL::PKey::RSA.new(File.read(CLIENT_KEY))
      ctx.ssl_version = :TLSv1_2
      # Wrap the socket with SSL/TLS
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
      ssl_socket.sync_close = true
      ssl_socket.connect
      ssl_socket
    end

    public
    def write(elements, opts={})
      elements = [elements] if elements.is_a?(Hash)
      send_window_size(elements.size)

      payload = elements.map { |element| JsonEncoder.to_frame(element, inc) }.join
      send_payload(payload)
    end

    public
    def read_ack
      ack = @socket.sysread(6)
      if ack.size > 2
        # ACK os size 2 are "2A" messages which are keep alive
        unpacked = ack.unpack('AAN')
        if unpacked[0] == "2" && unpacked[1] == "A"
          sequence_num = unpacked[2]
          #puts "Received ACK #{sequence_num}"
        end
      end
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

class Benchmark
  MB = 1024 * 1024
  KB = 1024

  attr_reader :client_count

  def initialize(traffic_type = :tcp, beats_ack = true, acks_per_second = nil)
    @client_count = 24 #cores * 2 = event loops threads
#     @total_traffic_for_connection = 256 * MB
    @total_traffic_for_connection = 1024 * MB
    # keep message size above 16k, requiring two TLS records
#     @message_sizes = [8 * KB, 16 * KB, 64 * KB, 128 * KB, 512 * KB]
    @message_sizes = [8 * KB]
    @traffic_type = traffic_type
    @beats_ack = beats_ack
    @acks_per_second = acks_per_second
  end

  def run
    puts "Using #{client_count} clients, starting at: #{Time.now()}"
    @message_sizes.each do |message_size|
      puts "\n\n"
      message = 'a' * message_size + "\n"
      test_iterations = 3
      repetitions = @total_traffic_for_connection / message_size
      puts "Expected to send #{repetitions * client_count * test_iterations} total messages, repetitions #{repetitions} for client of #{message_size}KB size"
      puts "Writing approximately #{(client_count * repetitions * message.size)/1024.0/1024.0}Mib across #{@client_count} clients (message size: #{message_size} Kb)"

      speeds = []
      test_iterations.times do
        speeds << execute_message_benchmark(message, repetitions)
      end

      puts "Terminated  at: #{Time.now()}"
      puts "Average evts(#{message_size}bytes)/sec (mean): #{speeds.sum / test_iterations} values: #{speeds}"
    end
  end

  private
  def execute_message_benchmark(message, repetitions)
    start = Time.now()
    sent_messages = java.util.concurrent.atomic.AtomicLong.new(0)

    if @traffic_type == :tcp
      tcp_traffic_load(client_count, message, repetitions, sent_messages)
    elsif @traffic_type == :beats
      beats_traffic_load(client_count, message, repetitions, sent_messages)
    else
      raise "Unrecognized traffic type: #{@traffic_type}"
    end

    puts "Done in #{Time.now() - start} seconds"

    sent_messages.get / (Time.now() - start)
  end

  private
  def tcp_traffic_load(client_count, message, repetitions, sent_messages)
    clients = @client_count.times.map { Lumberjack::Client.new }

    threads = client_count.times.map do |i|
      Thread.new(i) do |i|
        client = clients[i]
        # keep message size above 16k, requiring two TLS records
        repetitions.times do
          client.send_raw(message)
          sent_messages.incrementAndGet
        end
        client.close
      end
    end

    threads.each(&:join)
  end

  private
  def beats_traffic_load(client_count, message, repetitions, sent_messages)
    clients = @client_count.times.map { Lumberjack::Client.new }

    writer_threads = client_count.times.map do |i|
      Thread.new(i) do |i|
        client = clients[i]
        # keep message size above 16k, requiring two TLS records
        data = [ { "message" => message } ]
        repetitions.times do
          client.write(data) # this convert JSON to bytes
          sent_messages.incrementAndGet
        end
        client.close
      end
    end

    if @beats_ack
      puts "Starting ACK reading thread"
      reader_threads = client_count.times.map do |i|
        Thread.new(i) do |i|
          client = clients[i]
          exit = false
          acks_counter = 0;
          while (!exit)
            if acks_counter == @acks_per_second
              sleep 1
              acks_counter = 0
            end
            begin
              client.read_ack
              acks_counter = acks_counter + 1
            rescue
              puts "Closing reader thread for client #{i}"
              exit = true
            end
          end
        end
      end
    end

    writer_threads.each(&:join)
    reader_threads.each(&:join) if @beats_ack
  end
end

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby tcp_client.rb benchmark_client.rb --test=beats|tcp -ack [yes|no] --acks_per_second 1000"
  opts.on '-tKIND', '--test=KIND', 'Select to benchmark the TCP or Beats input'
  opts.on '-a' '--[no-]ack [FLAG]', TrueClass, 'In beats determine if read ACKs flow or not' do |v|
    options[:ack] = v.nil? ? true : v
  end
  opts.on("-fACKS", "--acks_per_second ACKS", Integer, "Rate ACKs per second")
end
option_parser.parse!(into: options)

puts "Parsed options: #{options}"

ack = options[:ack]

kind = :tcp
kind = options[:test].downcase.to_sym if options[:test]
acks_per_second = nil
acks_per_second = options[:acks_per_second] if options[:acks_per_second]

benchmark = Benchmark.new(kind, ack, acks_per_second)
benchmark.run