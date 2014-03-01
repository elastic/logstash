# encoding: utf-8
require "logstash/namespace"

class ::LogStash::Time < ::Time
  ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze

  if RUBY_PLATFORM == "java"
    JODA_ISO8601_PARSER = org.joda.time.format.ISODateTimeFormat.dateTimeParser
    #JODA_ISO8601_PARSER = org.joda.time.format.DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    UTC = org.joda.time.DateTimeZone.forID("UTC")
    def self.parse_iso8601(t)
      millis = JODA_ISO8601_PARSER.parseMillis(t)
      return ::LogStash::Time.at(millis / 1000, (millis % 1000) * 1000)
    end
  else
    def self.parse_iso8601(t)
      # Warning, ruby's Time.parse is *really* terrible and slow.
      return unless t.is_a?(String)
      return ::LogStash::Time.parse(t).utc
    end
  end

  def as_json(*)
    iso8601(3)
  end

  def to_json(*args)
    return as_json.to_json(*args)
  end

  def inspect
    return to_json
  end
end # class LogStash::Time
