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
end # module LogStash::Time
