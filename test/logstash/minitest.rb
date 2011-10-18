require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../lib"
$:.unshift File.dirname(__FILE__) + "/../"

require "minitest/spec"
require "logstash"

# Autorun if the caller script is the name of the process.
# Sort of like 'if $0 == __FILE__' but works with require()
parent = caller.collect { 
  |c| c.gsub(/:[0-9]+(:.*)$/, "")
}.find { |c| c != __FILE__ }
require "minitest/autorun" if parent == $0 or ENV["AUTORUN"]

# I don't really like monkeypatching, but whatever, this is probably better
# than overriding the 'describe' method.
class MiniTest::Spec
  class << self
    # 'it' sounds wrong, call it 'test'
    alias :test :it
  end
end
