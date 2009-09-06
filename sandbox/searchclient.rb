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
    #puts "Response (have #{$count} / want: #{$ids.length} acks); #{msg.inspect}"
    msg.results.each do |result|
      puts result
    end
    if msg.finished
      close
    end
  end
end

$me = Client.new(host="localhost", port=61613)

msg = LogStash::Net::Messages::SearchRequest.new
msg.log_type = ARGV[0]
msg.query = ARGV[1]
$me.sendmsg("/queue/logstash", msg)

$me.run
