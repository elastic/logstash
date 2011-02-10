
require "logstash/namespace"
require "logstash/logging"

class LogStash::Search::FacetResult
  # Array of LogStash::Event of results
  attr_accessor :facets

  # How long this query took, in seconds (or fractions of).
  attr_accessor :duration

  # Error message, if any.
  attr_accessor :error_message

  def initialize(settings={})
    @facets = {} # TODO(sissel): need something better?
    @duration = nil
    @error_message = nil
  end

  def error?
    return !@error_message.nil?
  end
end # class LogStash::Search::Result

