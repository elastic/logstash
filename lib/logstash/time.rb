
# Provide our own Time wrapper for ISO8601 support
# Example:
#   >> LogStash::Time.now.to_iso8601
#   => "2010-10-17 00:25:24.619014-0700"
#
#   >> LogStash::Time.now.utc.to_iso8601
#   => "2010-10-17 07:25:26.788704Z"
module LogStash; class Time < ::Time
  # Return a string that is this time in ISO8601 format.
  def to_iso8601
    if self.utc?
      tz = "Z"
    else
      tz = self.strftime("%z")
    end
    # zero-pad tv_usec so the time string is sortable.
    return "%s.%06d%s" % [self.strftime("%Y-%m-%dT%H:%M:%S"), self.tv_usec, tz]
  end
end; end # class LogStash::Time
