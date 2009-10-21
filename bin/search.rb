#!/usr/bin/ruby
#
require "rubygems"
require "lib/net/clients/search"
require "lib/config/base"
require "set"

Thread::abort_on_exception = true

def main(args)
  if ARGV.length != 3
    $stderr.puts "Usage: search configfile log_type query"
  end
  client = LogStash::Net::Clients::Search.new(args[0])
  client.search({
    :log_type => args[1],
    :query => args[2],
    :limit => 100,
  })

  # Wait for the client to decide it's done.
  client.run

  # Collate & print results.
  puts "Hits: #{client.hits}"
  puts ""
  puts client.results.sort_by { |r| r[0] }.collect { |r| r[1] }.join("\n")

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
