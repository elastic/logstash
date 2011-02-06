require "rubygems"
$:.unshift "#{File.dirname(__FILE__)}/../lib/"

# Fix for Ruby 1.9.x
$:.unshift "#{File.dirname(__FILE__)}"

require "logstash/test_syntax"
require "logstash/filters/test_date"
require "logstash/filters/test_grep"
require "logstash/filters/test_multiline"
require "logstash/inputs/test_file"
require "logstash/inputs/test_syslog"
require "logstash/inputs/test_stomp"
require "logstash/outputs/test_elasticsearch"
