#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/servers/indexer'

if ENV.has_key?("PROFILE")
  require 'ruby-prof'
  RubyProf.start

  #class String
    #alias_method :orig_scan, :scan
    #def scan(*args)
      ##raise
      #return orig_scan(*args)
    #end
  #end
end
Thread::abort_on_exception = true
s = LogStash::Net::Servers::Indexer.new(username='', password='', host="localhost")
s.run

if ENV.has_key?("PROFILE")
  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT, 0)
end
