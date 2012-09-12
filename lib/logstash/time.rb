require "logstash/namespace"

# Provide our own Time wrapper for ISO8601 support
# Example:
#   >> LogStash::Time.now.to_iso8601
#   => "2010-10-17 00:25:24.619014-0700"
#
#   >> LogStash::Time.now.utc.to_iso8601
#   => "2010-10-17 07:25:26.788704Z"
module LogStash::Time
  if RUBY_ENGINE == "jruby"
    require "java"
    DateTime = org.joda.time.DateTime
    def self.now
      # org.joda.time.DateTime#to_s returns the time in ISO8601 form :)
      return DateTime.new.to_s
    end # def initialize
  else
    # Otherwise, use ruby stdlib Time, which is much slower than Joda.
    ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze
    def self.now
      now = Time.new
      return sprintf(ISO8601_STRFTIME, now.year, now.month, now.day, now.hour,
                     now.min, now.sec, now.tv_usec, now.utc_offset / 3600)
    end
  end
end # module LogStash::Time
