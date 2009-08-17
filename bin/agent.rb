#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/client'
require 'lib/net/messages/indexevent'
require 'lib/file/tail/since'
require 'socket'


class Agent < LogStash::Net::MessageClient
  def initialize(host, port)
    super()
    @hostname = Socket.gethostname
    @host = host
    @port = port
    @watcher = nil
    start_log_watcher
  end # def initialize

  def start_log_watcher
    Thread.new do
      File::Tail::Since.new("/var/log/messages").tail do |line|
        line.chomp!
        puts "Found line: #{line}"
        index(line)
      end
    end
  end # def start_log_watcher

  def index(string)
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = "linux-syslog"
    ier.log_data = string
    ier.metadata["source_host"] = @hostname

    sent = false
    while !sent
      begin
        puts "Trying to send: #{ier.inspect}"
        sendmsg(ier)
        sent = true
      rescue LogStash::Net::NoSocket
        # No client connection available, wait.
        puts "No client connection available to send on, sleeping..."
        sleep 1
      end
    end
  end # def index

  def IndexEventResponseHandler(msg)
    if msg.success?
    end
  end # def IndexEventResponseHandler

  def run
    loop do
      done = false
      while !done
        begin
          done = connect(@host, @port); 
        rescue Errno::ECONNREFUSED => e
          puts "Connection to #{@host}:#{@port} failed: #{e}"
          puts "Sleeping for retry."
          sleep 1
        end
      end
      puts "Connection OK"

      begin
        loop do
          sendrecv(nil)
        end
      rescue LogStash::Net::MessageClientConnectionReset
        puts "Connection died, retrying..."
      end
    end
  end # def run

end


if $0 == __FILE__
  if ARGV.length == 0
    puts "Usage: #{$0} host:port"
    exit 1
  end
  host, port = ARGV[0].split(":")
  agent = Agent.new(host, port)
  agent.run
end
