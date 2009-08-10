#!/usr/bin/ruby
#

require "socket"
require "lib/net/message"
require "lib/net/socketmux"
require "lib/net/messages/indexevent"

class Client < LogStash::Net::MessageSocketMux
  def IndexEventResponseHandler(msg)
    puts "Response; #{msg.inspect}"
  end
end

me = Client.new
me.connect("localhost", 3001)

File.open(ARGV[0]).each do |line|
  ier = LogStash::Net::Messages::IndexEventRequest.new
  ier.log_type = "syslog"
  ier.log_data = line[0..-2]
  ier.metadata["source_host"] = "snack.home"
  me.sendmsg(ier)
end

me.run
