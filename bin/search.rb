#!/usr/bin/ruby
#
require 'rubygems'
require "socket"
require "lib/net/message"
require "lib/net/client"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/ping"
require "set"

$done = false
$lastid = nil
$count = 0
$time = 0
$start = Time.now.to_f

class Client < LogStash::Net::MessageClient
  def SearchResponseHandler(msg)
    msg.results.each do |result|
      puts result
    end
    if msg.finished
      close
    end
  end
end

def main(args)
  client = Client.new(host="localhost", port=61613)
  msg = LogStash::Net::Messages::SearchRequest.new
  msg.log_type = args[0]
  msg.query = args[1]
  client.sendmsg("/queue/logstash", msg)
  client.run
end

if $0 == __FILE__
  exit main(ARGV)
end
