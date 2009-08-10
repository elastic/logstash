#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/server"
require "lib/net/servers/indexer"

s = LogStash::Net::Servers::Indexer.new

s.run
