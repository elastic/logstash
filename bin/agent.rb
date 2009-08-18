#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/client'
require 'lib/net/messages/indexevent'
require 'lib/file/tail/since'
require 'socket'


class Agent < LogStash::Net::MessageClient
  def initialize(host, port)
    super(host, port)
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
        index("linux-syslog", line)
      end
    end

    Thread.new do
      File::Tail::Since.new("/b/access").tail do |line|
        line.chomp!
        index("httpd-access", line)
      end
    end
  end # def start_log_watcher

  def index(type, string)
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = type
    ier.log_data = string
    ier.metadata["source_host"] = @hostname

    sent = false
    while !sent
      begin
        $stdout.write(".")
        $stdout.flush
        #puts "Trying to send: #{ier.inspect}"
        @connection.sendmsg(ier)
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
end


if $0 == __FILE__
  if ARGV.length == 0
    puts "Usage: #{$0} host:port"
    exit 1
  end
  host, port = ARGV[0].split(":")
  agent = Agent.new(host, port)

  agent.run do |i|
    # nothing
  end
end
