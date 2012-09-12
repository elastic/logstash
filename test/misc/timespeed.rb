$: << "lib"
require "logstash/time"

start = Time.now
count = 500000

count.times { LogStash::Time.now }
duration = Time.now - start
rate = count / duration

puts "Rate: #{rate}"
