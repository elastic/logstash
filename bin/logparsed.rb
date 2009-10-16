#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/servers/parser'

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

  s = LogStash::Net::Servers::Parser.new(args[0])
  s.run

  if ENV.has_key?("PROFILE")
    result = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, 0)
  end

  return 0
end

procs = 4
if procs > 1
  children = []
  1.upto(procs) do |c|
    pid = fork do
      exit main(ARGV)
    end
    children << pid
  end

  while children.length > 0
    pid = Process.wait(children[0], 0)
    children.delete(pid)
    puts "pid #{pid} died"
  end
else
  exit main(ARGV)
end
