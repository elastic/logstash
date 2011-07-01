require "rubygems"
$:.unshift "#{File.dirname(__FILE__)}/../lib/"

# Fix for Ruby 1.9.x
$:.unshift "#{File.dirname(__FILE__)}"

def skip(path)
  puts "Skipping tests: #{path}"
end

def use(path)
  puts "Loading tests from #{path}"
  require path
end

use "logstash/test_syntax"
use "logstash/test_event"
use "logstash/filters/test_date"
use "logstash/filters/test_grep"
use "logstash/filters/test_multiline"
use "logstash/filters/test_grok"

if __FILE__ =~ /^file:.*\.jar/
  puts "Skipping elasticsearch tests since we're running from a jar."
  skip "logstash/outputs/test_elasticsearch"
else
  use "logstash/outputs/test_elasticsearch"
end

skip "logstash/inputs/test_file"
skip "logstash/inputs/test_syslog"
skip "logstash/inputs/test_stomp"

#Test::Unit::AutoRunner.run
