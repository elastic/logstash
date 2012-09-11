require "logstash/namespace"
require "date" # for DateTime

# Provide our own Time wrapper for ISO8601 support
# Example:
#   >> LogStash::Time.now.to_iso8601
#   => "2010-10-17 00:25:24.619014-0700"
#
#   >> LogStash::Time.now.utc.to_iso8601
#   => "2010-10-17 07:25:26.788704Z"
class LogStash::Time
  if RUBY_ENGINE == "jruby"
    require "java"
    DateTime = org.joda.time.DateTime
    def initialize
      # org.joda.time.DateTime#to_s returns the time in ISO8601 form :)
      @time = DateTime.new.to_s
    end # def initialize
  else
    # Otherwise, use ruby stdlib Time, which is much slower than Joda.
    ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze
    def initialize
      now = Time.new
      @time = sprintf(ISO8601_STRFTIME, now.year, now.month, now.day, now.hour,
                      now.min, now.sec, now.tv_usec, now.utc_offset / 3600)
    end

  end

  def to_s
    return @time
  end
end # class LogStash::Time
