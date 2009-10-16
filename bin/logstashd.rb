#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/servers/indexer'

def main(args)
  if args.length != 1
    puts "Usage: #{$0} configfile"
    return 1
  end
  Thread::abort_on_exception = true

  if ENV.has_key?("PROFILE")
    require 'ruby-prof'
    RubyProf.start
  end

  s = LogStash::Net::Servers::Indexer.new(args[0])
  s.run

  if ENV.has_key?("PROFILE")
    result = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, 0)
  end

  return 0
end

exit main(ARGV)
