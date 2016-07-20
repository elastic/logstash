# encoding: utf-8
require "benchmark/ips"
require "logstash/event"

options = { :time => 10, :warmup => 60 }
puts "Same Event instance"

event = LogStash::Event.new("foo" => {"bar" => {"foobar" => "morebar"} })
STDERR.puts ""
STDERR.puts " ----------> event.get(\"[foo][bar][foobar]\") => #{event.get("[foo][bar][foobar]")}"
STDERR.puts ""

Benchmark.ips do |x|
  x.config(options)

  x.report("Deep fetch") { event.get("[foo][bar][foobar]") }
end
