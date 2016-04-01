# encoding: utf-8
require "benchmark/ips"
require "logstash/event"

options = { :time => 10, :warmup => 10 }
puts "Same Event instance"

event = LogStash::Event.new("foo" => {"bar" => {"foobar" => "morebar"} })
STDERR.puts " ----------> event[\"[foo][bar][foobar]\"] = #{event["[foo][bar][foobar]"]}"

Benchmark.ips do |x|
  x.config(options)

  x.report("Deep fetch") { event["[foo][bar][foobar]"] }
end
