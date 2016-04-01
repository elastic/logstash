# encoding: utf-8
require "benchmark/ips"
require "logstash/event"

options = { :time => 10, :warmup => 10 }
puts "Same Event instance"
Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("Deep fetch") { event.sprintf("/first/%{foo}/%{foobar}/%{+YYY-mm-dd}") }
end
