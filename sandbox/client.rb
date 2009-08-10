#!/usr/bin/ruby
#

require "socket"
require "lib/net/message"
require "lib/net/socketmux"
require "lib/net/messages/indexevent"
require "set"

$done = false
$lastid = nil
$count = 0

class Client < LogStash::Net::MessageSocketMux
  def IndexEventResponseHandler(msg)
    $count += 1
    puts "Response (have #{$count} / want: #{$ids.length} acks); #{msg.inspect}"
    $ids.delete(msg.id)
    if $done and $ids.length == 0
      puts "All messages ACK'd (#{$lastid})"
      exit(0)
    end
  end
end

$me = Client.new
$me.connect("localhost", 3001)
$ids = Set.new

def dumplog

  File.open(ARGV[0]).each do |line|
    #puts "Line: #{line}"
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = "syslog"
    #ier.log_data = line[0..-2]
    ier.metadata["source_host"] = "snack.home"
    #ier.generate_id!
    $me.sendmsg(ier)
    puts "Request; #{ier.inspect}"
    $ids << ier.id
    #sleep 0.1
  end

  $me.close()
  $done = true
  #puts "dumper done"
end

y = Thread.new { $me.run }
x = Thread.new { dumplog }
y.join
x.join
