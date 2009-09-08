#!/usr/bin/env ruby
#

require "rubygems"
require "lib/net/servers/indexer"

Thread::abort_on_exception = true
s = LogStash::Net::Servers::Indexer.new(host="snack.home")
s.run

