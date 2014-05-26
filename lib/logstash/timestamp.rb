# encoding: utf-8
require "logstash/environment"
require "logstash/json"
require "forwardable"
require "date"
require "time"

module LogStash
  class TimestampParserError < StandardError; end

  class Timestamp
    extend Forwardable

    def_delegators :@time, :tv_usec, :usec, :year, :iso8601, :to_i, :tv_sec, :to_f, :to_edn

    attr_reader :time

    ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze
    ISO8601_PRECISION = 3

    def initialize(time = Time.new)
      @time = time.utc
    end

    def self.at(*args)
      Timestamp.new(::Time.at(*args))
    end

    def self.parse(*args)
      Timestamp.new(::Time.parse(*args))
    end

    def self.now
      Timestamp.new(::Time.now)
    end

    # coerce tries different strategies based on the time object class to convert into a Timestamp.
    # @param [String, Time, Timestamp] time the time object to try coerce
    # @return [Timestamp, nil] Timestamp will be returned if successful otherwise nil
    # @raise [TimestampParserError] on String with invalid format
    def self.coerce(time)
      case time
      when String
        LogStash::Timestamp.parse_iso8601(time)
      when LogStash::Timestamp
        time
      when Time
        LogStash::Timestamp.new(time)
      else
        nil
      end
    end

    if LogStash::Environment.jruby?
      JODA_ISO8601_PARSER = org.joda.time.format.ISODateTimeFormat.dateTimeParser
      UTC = org.joda.time.DateTimeZone.forID("UTC")

      def self.parse_iso8601(t)
        millis = JODA_ISO8601_PARSER.parseMillis(t)
        LogStash::Timestamp.at(millis / 1000, (millis % 1000) * 1000)
      rescue => e
        raise(TimestampParserError, "invalid timestamp string #{t.inspect}, error=#{e.inspect}")
      end

    else

      def self.parse_iso8601(t)
        # warning, ruby's Time.parse is *really* terrible and slow.
        LogStash::Timestamp.new(::Time.parse(t))
      rescue => e
        raise(TimestampParserError, "invalid timestamp string #{t.inspect}, error=#{e.inspect}")
      end
    end

    def utc
      @time.utc # modifies the receiver
      self
    end
    alias_method :gmtime, :utc

    def to_json
      LogStash::Json.dump(@time.iso8601(ISO8601_PRECISION))
    end
    alias_method :inspect, :to_json

    def to_iso8601
      @time.iso8601(ISO8601_PRECISION)
    end
    alias_method :to_s, :to_iso8601

  end
end
