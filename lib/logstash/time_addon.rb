# encoding: utf-8
require "logstash/namespace"

# Provide our own Time wrapper for ISO8601 support
# Example:
#   >> LogStash::Time.now.to_iso8601
#   => "2010-10-17 00:25:24.619014-0700"
#
#   >> LogStash::Time.now.utc.to_iso8601
#   => "2010-10-17 07:25:26.788704Z"
module LogStash::Time
  ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze
  def self.now
    return Time.new.utc
  end

  if RUBY_PLATFORM == "java"
    #JODA_ISO8601_PARSER = org.joda.time.format.ISODateTimeFormat.dateTimeParser
    #JODA_ISO8601_PARSER = org.joda.time.format.ISODateTimeFormat.dateTimeParser
    JODA_ISO8601_PARSER = org.joda.time.format.DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    UTC = org.joda.time.DateTimeZone.forID("UTC")
    def self.parse_iso8601(t)
      millis = JODA_ISO8601_PARSER.parseMillis(t)
      return Time.at(millis / 1000, (millis % 1000) * 1000)
    end
  else
    def self.parse_iso8601(t)
      # Warning, ruby's Time.parse is *really* terrible and slow.
      return unless t.is_a?(String)
      return Time.parse(t).gmtime
    end
  end
end # module LogStash::Time
