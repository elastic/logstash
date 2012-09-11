$: << "lib"
require "logstash/event"
require "thread"

q = Queue.new

Thread.abort_on_exception = true
iterations = 500000

Thread.new { iterations.times { |i| q << LogStash::Event.new } }

start = Time.now
popper = Thread.new { iterations.times { q.pop } }
popper.join
duration = Time.now - start
rate = iterations / duration
puts "Rate: #{rate}"
