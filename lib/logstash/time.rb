
# Provide our own Time wrapper for ISO8601 support
# Example:
#   >> LogStash::Time.now.to_iso8601
#   => "2010-10-17 00:25:24.619014-0700"
#
#   >> LogStash::Time.now.utc.to_iso8601
#   => "2010-10-17 07:25:26.788704Z"
module LogStash; class Time < ::Time
  ISO8601 = "%Y-%m-%dT%H:%M:%S"

  # Return a string that is this time in ISO8601 format.
  def to_iso8601
    tz = self.utc? ? "Z" : self.strftime("%z")
    # zero-pad tv_usec so the time string is sortable.
    return "%s.%06d%s" % [self.strftime(ISO8601), self.tv_usec, tz]
  end

  def self.to_iso8601(obj)
    if obj.is_a?(DateTime)
      tz = obj.offset == 0 ? "Z" : obj.strftime("%z")
      return "%s.%06d%s" % [obj.strftime(ISO8601), obj.sec_fraction.to_f, tz]
    else
      raise "Can't convert object of type #{obj.class} (#{obj}) to iso8601."
    end
  end
end; end # class LogStash::Time
