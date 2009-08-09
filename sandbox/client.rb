#!/usr/bin/ruby
#

require "socket"
require "lib/net/message"
require "lib/net/messages/indexevent"

x = TCPSocket.new("localhost", 4044)

ms = Logstash::MessageStream.new
ier = Logstash::IndexEventRequest.new
ier.log_type = "apache"
ier.log_data = "once upon a time in apache..."
ier.metadata["source_host"] = "snack.home"

ms << ier
data = ms.encode
x.write([data.length, data].pack("NA*"))

