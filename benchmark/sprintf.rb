require "benchmark/ips"
require "lib/logstash/event"

options = { :time => 10, :warmup => 10 }
Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("Complex No cache: Event#old_sprintf") { event.old_sprintf("/first/%{foo}/%{foobar}/%{+YYY-mm-dd}") }
  x.report("Complex cached: Event#sprintf") { event.sprintf("/first/%{foo}/%{foobar}/%{+YYY-mm-dd}") }
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("Date only No cache: Event#old_sprintf") { event.old_sprintf("%{+YYY-mm-dd}") }
  x.report("Date only cached: Event#sprintf") { event.sprintf("%{+YYY-mm-dd}") }
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("string only No cache: Event#old_sprintf") { event.old_sprintf("bleh") }
  x.report("string only cached: Event#sprintf") { event.sprintf("bleh") }
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("key only No cache: Event#old_sprintf") { event.old_sprintf("%{foo}") }
  x.report("key only cached: Event#sprintf") { event.sprintf("%{foo}") }
  x.compare!
end
