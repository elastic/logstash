#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/message"
require "lib/net/messages/indexevent"

ms = LogStash::Net::MessageStream.new
(1 .. 3).each do |i|
  x = LogStash::Net::Messages::IndexEventRequest.new
  x.log_type = "apache"
  ms << x
end

z = LogStash::Net::Messages::IndexEventResponse.new
z.id = 2

ms << z

LogStash::Net::MessageStream.decode(ms.encode) do |msg|
  puts msg.inspect
end
