require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../lib"
$:.unshift File.dirname(__FILE__) + "/../"

require "minitest/spec"
require "logstash"

# Autorun if the process name is a script in test/logstash/
if File.expand_path($0) =~ /test\/logstash\//
  require "minitest/autorun"
end

# I don't really like monkeypatching, but whatever, this is probably better
# than overriding the 'describe' method.
class MiniTest::Spec
  class << self
    # 'it' sounds wrong, call it 'test'
    alias :test :it
  end
end
