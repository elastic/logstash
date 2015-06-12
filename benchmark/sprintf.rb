require "benchmark/ips"
require "lib/logstash/event"

options = { :time => 10, :warmup => 10 }
puts "Same Event instance"
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

puts "New Event on each iteration"
Benchmark.ips do |x|
  x.config(options)

  x.report("Complex No cache: Event#old_sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")
    event.old_sprintf("/first/%{foo}/%{foobar}/%{+YYY-mm-dd}")
  end

  x.report("Complex cached: Event#sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")
    event.sprintf("/first/%{foo}/%{foobar}/%{+YYY-mm-dd}")
  end
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  x.report("Date only No cache: Event#old_sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

    event.old_sprintf("%{+YYY-mm-dd}")
  end

  x.report("Date only cached: Event#sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")

    event.sprintf("%{+YYY-mm-dd}")
  end
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("string only No cache: Event#old_sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")

    event.old_sprintf("bleh")
  end
  x.report("string only cached: Event#sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")
    event.sprintf("bleh")
  end
  x.compare!
end

Benchmark.ips do |x|
  x.config(options)
  event = LogStash::Event.new("foo" => "bar",
                    "foobar" => "morebar")

  x.report("key only No cache: Event#old_sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")
    event.old_sprintf("%{foo}")
  end
  x.report("key only cached: Event#sprintf") do
    event = LogStash::Event.new("foo" => "bar",
                                "foobar" => "morebar")
    event.sprintf("%{foo}")
  end
  x.compare!
end
