require "logstash/namespace"
require "logstash/logging"

class LogStash::Search::Result
  # Array of LogStash::Event of results
  attr_accessor :events

  # How long this query took, in seconds (or fractions of).
  attr_accessor :duration

  # Offset in search
  attr_accessor :offset

  # Total records matched by this query, regardless of offset/count in query.
  attr_accessor :total

  # Error message, if any.
  attr_accessor :error_message

  public
  def initialize(settings={})
    @events = []
    @duration = nil
    @error_message = nil
  end

  public
  def error?
    return !@error_message.nil?
  end

  public
  def to_json
    return to_hash.to_json
  end # def to_json

  public
  def to_hash
    return {
      "events" => @events,
      "duration" => @duration,
      "offset" => @offset,
      "total" => @total,
    }
  end # def to_hash
end # class LogStash::Search::Result

