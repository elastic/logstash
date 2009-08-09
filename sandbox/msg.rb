#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/message"
require "lib/net/messages/indexevent"

ms = Logstash::MessageStream.new
(1 .. 3).each do |i|
  x = Logstash::IndexEventRequest.new
  x.log_type = "apache"
  ms << x
end

z = Logstash::IndexEventResponse.new
z.id = 2

ms << z

Logstash::MessageStream.decode(ms.encode) do |msg|
  puts msg.inspect
end
