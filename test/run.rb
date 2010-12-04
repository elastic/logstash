require "rubygems"
$:.unshift "#{File.dirname(__FILE__)}/../lib/"

require "logstash/test_syntax"
require "logstash/filters/test_date"
require "logstash/filters/test_grep"
require "logstash/filters/test_multiline"
