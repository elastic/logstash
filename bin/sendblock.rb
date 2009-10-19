#!/usr/bin/ruby
#
require 'rubygems'
require "socket"
require "lib/net/message"
require "lib/net/client"
require "lib/net/messages/directory"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/searchhits"
require "lib/net/messages/ping"
require "set"
require "thread"

Thread::abort_on_exception = true

class SearchClient < LogStash::Net::MessageClient
end

def main(args)
  client = SearchClient.new
  msg = LogStash::Net::Messages::PingRequest.new
  op = client.sendmsg("logstash-directory", msg) do |response|
    puts response
    :finished
  end

  op.wait_until_finished
  puts "Done!"

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
