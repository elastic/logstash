#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/servers/indexer"

s = LogStash::Net::Servers::Indexer.new(host="snack.home")
s.run

