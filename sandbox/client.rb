#!/usr/bin/ruby
#

require 'rubygems'
require "socket"
require "lib/net/message"
require "lib/net/client"
require "lib/net/messages/indexevent"
require "lib/net/messages/ping"
require "set"

$done = false
$lastid = nil
$count = 0
$time = 0
$start = Time.now.to_f
$ids = Hash.new

class Client < LogStash::Net::MessageClient
  def gotresponse(msg)
    $count += 1
    $ids.delete(msg.id)

    if $done and $ids.length == 0
      puts "All messages ACK'd (#{$lastid})"
      exit(0)
    end
  end

  def IndexEventResponseHandler(msg)
    #puts "Response (have #{$count} / want: #{$ids.length} acks); #{msg.inspect}"
    if !msg.success?
      req = $ids[msg.id]
      puts "FAIL: #{req.inspect}"
    end
    #if $ids.length < 5
      #puts $ids.collect { |k,v| "#{k.inspect}: #{v.inspect}" }.join(", ")
    #end
    gotresponse(msg)
  end

  def PingResponseHandler(msg)

    now = Time.now.to_f()
    $time += (now - msg.pingdata)
    rate = $count / (now - $start)

    puts "\rK#{$time / $count} (#{rate})"
    gotresponse(msg)
  end
end

$me = Client.new
$me.connect("localhost", 3001)

def dumplog

  msgqueue = []
  File.open(ARGV[0]).each do |line|
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = "linux-syslog"
    ier.log_data = line[0..-2]
    ier.metadata["source_host"] = "snack.home"

    msgqueue << ier

    #ping = LogStash::Net::Messages::PingRequest.new
    #msgqueue << ping
    if msgqueue.length > 20
      $me.sendmsg(msgqueue)
      msgqueue.each do |msg|
        $ids[msg.id] = msg
      end
      msgqueue.clear
    end

    # Exponential backoff.
    time = 0.2
    while $ids.length > 200
      puts "Too many messages waiting on ACK, sleeping..."
      sleep time
      time *= 2
      if time > 30
        time = 30
      end
    end
  end

    if msgqueue.length > 20
      puts "Leftovers..."
      $me.sendmsg(msgqueue)
      msgqueue.clear
    end

  $me.close()
  $done = true
  #puts "dumper done"
end

y = Thread.new { $me.run }
x = Thread.new { dumplog }
y.join
x.join
