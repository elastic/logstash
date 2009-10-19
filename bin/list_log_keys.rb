#!/usr/bin/ruby
#
require 'rubygems'
require "socket"
require "lib/net/message"
require "lib/net/client"
require "lib/net/messages/logkeys"

Thread::abort_on_exception = true

class LogKeysClient < LogStash::Net::MessageClient
  attr_reader :keys

  def initialize(opts)
    @log_type = opts[:log_type]
    @keys = []
    super(opts)
    start
  end

  def start
    msg = LogStash::Net::Messages::LogKeysRequest.new
    msg.log_type = @log_type
    sendmsg("logstash-index", msg)
    run
  end

  def LogKeysResponseHandler(msg)
    @keys = msg.keys
    close
  end
end

def main(args)
  client = LogKeysClient.new(:log_type => args[0], :host => "localhost")

  # Collate & print results.
  puts "Log keys for #{args[0]}:"
  client.keys.each { |t| puts " - #{t}" }

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
