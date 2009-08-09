#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/server"

s = Logstash::MessageServer.new

s.run
