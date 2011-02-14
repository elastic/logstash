
require "logstash/namespace"
require "logstash/logging"

class LogStash::Search::FacetResult
  # Array of LogStash::Search::FacetResult::Entry
  attr_accessor :results

  # How long this query took, in seconds (or fractions of).
  attr_accessor :duration

  # Error message, if any.
  attr_accessor :error_message

  def initialize(settings={})
    @results = []
    @duration = nil
    @error_message = nil
  end

  def error?
    return !@error_message.nil?
  end
end # class LogStash::Search::FacetResult

