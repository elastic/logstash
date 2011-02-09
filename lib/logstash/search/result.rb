require "logstash/namespace"
require "logstash/logging"

class LogStash::Search::Result
  attr_accessor :events
  attr_accessor :duration

  attr_accessor :error_message

  def initialize(settings={})
    @events = []
    @duration = nil
    @error_message = nil
  end

  def error?
    return !@error_message.nil?
  end
end # class LogStash::Search::Result

