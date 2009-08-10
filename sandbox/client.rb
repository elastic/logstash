#!/usr/bin/ruby
#

require "socket"
require "lib/net/message"
require "lib/net/socketmux"
require "lib/net/messages/indexevent"

$lastid = nil

class Client < LogStash::Net::MessageSocketMux
  def IndexEventResponseHandler(msg)
    #puts "Response (want: #{X.lastid}); #{msg.inspect}"
    if msg.id == $lastid
      puts "All messages ACK'd"
      exit(0)
    end
  end
end

$me = Client.new
$me.connect("localhost", 3001)

def dumplog
  File.open(ARGV[0]).each do |line|
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = "syslog"
    ier.log_data = line[0..-2]
    ier.metadata["source_host"] = "snack.home"
    $me.sendmsg(ier)
    #puts "Queued #{ier}"
    $lastid = ier.id
  end

  $me.close()
end

x = Thread.new { dumplog }
y = Thread.new { $me.run }
x.join
y.join
