require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "socket"
require "logstash/namespace"

class LogStash::TestCase < Test::Unit::TestCase
  def setup
    super
    @type = "default"
    @hostname = Socket.gethostname
  end

  # We have to include at least one test here, otherwise Test::Unit barfs about
  # not tests for this class, even though it's just a superclass for real test
  # cases.
  def test_ok; end
end # class LogStash::TestCase
