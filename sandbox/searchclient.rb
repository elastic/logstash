#!/usr/bin/ruby
#
require 'rubygems'
require "socket"
require "lib/net/message"
require "lib/net/socketmux"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/ping"
require "set"

$done = false
$lastid = nil
$count = 0
$time = 0
$start = Time.now.to_f

class Client < LogStash::Net::MessageSocketMux
  def gotresponse(msg)
    $count += 1
    $ids.delete(msg.id)

    if $done and $ids.length == 0
      puts "All messages ACK'd (#{$lastid})"
      exit(0)
    end
  end

  def SearchResponseHandler(msg)
    #puts "Response (have #{$count} / want: #{$ids.length} acks); #{msg.inspect}"
    msg.results.each do |result|
      puts result
    end
    #gotresponse(msg)
  end
end

$me = Client.new
$me.connect("localhost", 3001)
$ids = Set.new

msg = LogStash::Net::Messages::SearchRequest.new
msg.log_type = ARGV[0]
msg.query = ARGV[1]

msg = LogStash::Net::Messages::SearchRequest.new
msg.log_type = ARGV[0]
msg.query = ARGV[1]
$me.sendmsg(msg)
$done = true
$me.close()
$done = true
$me.run
