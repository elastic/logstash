require "rubygems"
require File.join(File.dirname(__FILE__), "logstash", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"

require "tmpdir"
require "mocha"
require 'shoulda'
