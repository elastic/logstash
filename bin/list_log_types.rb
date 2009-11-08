#!/usr/bin/ruby
#
require 'rubygems'
require "socket"
require "lib/net/client"
require "lib/net/messages/logtypes"

Thread::abort_on_exception = true

class LogTypesClient < LogStash::Net::MessageClient
  attr_reader :types

  def initialize(opts)
    @types = []
    super(opts)
    start
  end

  def start
    msg = LogStash::Net::Messages::LogTypesRequest.new
    sendmsg("logstash-index", msg)
    run
  end

  def LogTypesResponseHandler(msg)
    @types = msg.types
    close
  end
end

def main(args)
  client = LogTypesClient.new(:host => "localhost")

  # Collate & print results.
  puts "Log types:"
  client.types.each { |t| puts " - #{t}" }

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
