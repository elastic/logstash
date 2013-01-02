require "logstash/filters/base"
require "logstash/namespace"
require "logstash/time_addon"

# The date filter is used for parsing dates from fields and using that
# date or timestamp as the timestamp for the event.
#
# For example, syslog events usually have timestamps like this:
#
#     "Apr 17 09:32:01"
#
# You would use the date format "MMM dd HH:mm:ss" to parse this.
#
# The date filter is especially important for sorting events and for
# backfilling old data. If you don't get the date correct in your
# event, then searching for them later will likely sort out of order.
#
# In the absence of this filter, logstash will choose a timestamp based on the
# first time it sees the event (at input time), if the timestamp is not already
# set in the event. For example, with file input, the timestamp is set to the
# time of reading.
class LogStash::Filters::Date < LogStash::Filters::Base
  JavaException = java.lang.Exception if RUBY_ENGINE == "jruby"

  config_name "date"
  plugin_status "stable"

  # specify a locale to be used for date parsing. If this is not specified the platform default will be
  # used
  #
  # The locale is mostly necessary to be set for parsing month names and weekday names
  #
  config :locale, :validate => :string

  # Config for date is:
  #
  #     fieldname => dateformat
  #
  # The same field can be specified multiple times (or multiple dateformats for
  # the same field) do try different time formats; first success wins.
  #
  # The date formats allowed are anything allowed by Joda-Time (java time
  # library), generally: [java.text.SimpleDateFormat][dateformats]
  #
  # There are a few special exceptions, the following format literals exist
  # to help you save time and ensure correctness of date parsing.
  #
  # * "ISO8601" - should parse any valid ISO8601 timestamp, such as
  #   2011-04-19T03:44:01.103Z
  # * "UNIX" - will parse unix time in seconds since epoch
  # * "UNIX_MS" - will parse unix time in milliseconds since epoch
  # * "TAI64N" - will parse tai64n time values
  #
  # For example, if you have a field 'logdate' and with a value that looks like
  # 'Aug 13 2010 00:03:44'
  # you would use this configuration:
  #
  #     logdate => "MMM dd YYYY HH:mm:ss"
  #
  # [dateformats]: http://download.oracle.com/javase/1.4.2/docs/api/java/text/SimpleDateFormat.html
  config /[A-Za-z0-9_-]+/, :validate => :array

  # The date formats allowed are anything allowed by Joda-Time (java time
  # library), generally: [java.text.SimpleDateFormat][dateformats]
  #
  # An array with field name first, and format patterns following, [ field,
  # formats... ]
  #
  # If your time field has multiple possible formats, you can do this:
  #
  #     match => [ "logdate", "MMM dd YYY HH:mm:ss",
  #               "MMM  d YYY HH:mm:ss", "ISO8601" ]
  #
  # The above will match a syslog (rfc3164) or iso8601 timestamp.
  #
  # There are a few special exceptions, the following format literals exist
  # to help you save time and ensure correctness of date parsing.
  #
  # * "ISO8601" - should parse any valid ISO8601 timestamp, such as
  #   2011-04-19T03:44:01.103Z
  # * "UNIX" - will parse unix time in seconds since epoch
  # * "UNIX_MS" - will parse unix time in milliseconds since epoch
  # * "TAI64N" - will parse tai64n time values
  #
  # For example, if you have a field 'logdate' and with a value that looks like
  # 'Aug 13 2010 00:03:44', you would use this configuration:
  #
  #     filter {
  #       date {
  #         match => [ "logdate", "MMM dd YYYY HH:mm:ss" ]
  #       }
  #     }
  #
  config :match, :validate => :array, :default => []

  # LOGSTASH-34
  DATEPATTERNS = %w{ y d H m s S } 

  # The 'date' filter will take a value from your event and use it as the
  # event timestamp. This is useful for parsing logs generated on remote
  # servers or for importing old logs.
  #
  # The config looks like this:
  #
  #     filter {
  #       date {
  #         type => "typename"
  #         filename => fieldformat
  #         # Example:
  #         timestamp => "mmm DD HH:mm:ss"
  #       }
  #     }
  #
  # The format is whatever is supported by Joda; generally:
  # http://download.oracle.com/javase/1.4.2/docs/api/java/text/SimpleDateFormat.html
  #
  # TODO(sissel): Support 'seconds since epoch' parsing (nagios uses this)
  public
  def initialize(config = {})
    super

    @parsers = Hash.new { |h,k| h[k] = [] }
  end # def initialize

  private
  def parseLocale(localeString)
    return nil if localeString == nil
    matches = localeString.match(/(?<lang>.+?)(?:_(?<country>.+?))?(?:_(?<variant>.+))?/)
    lang = matches['lang'] == nil ? "" : matches['lang'].strip()
    country = matches['country'] == nil ? "" : matches['country'].strip()
    variant = matches['variant'] == nil ? "" : matches['variant'].strip()
    return lang.length > 0 ? java.util.Locale.new(lang, country, variant) : nil
  end

  public
  def register
    require "java"
    # TODO(sissel): Need a way of capturing regexp configs better.
    locale = parseLocale(@config["locale"][0]) if @config["locale"] != nil and @config["locale"][0] != nil
    missing = []
    @config.each do |field, value|
      next if (RESERVED + ["locale"]).include?(field)
      next if (RESERVED + ["match"]).include?(field)

      # values here are an array of format strings for the given field.
      setupMatcher(field, locale, missing, value) # value.each
    end # @config.each
    setupMatcher(@config["match"].shift, locale, missing, @config["match"] )
  end

  def setupMatcher(field, locale, missing, value)
    value.each do |format|
      case format
        when "ISO8601"
          joda_parser = org.joda.time.format.ISODateTimeFormat.dateTimeParser.withOffsetParsed
          parser = lambda { |date| joda_parser.parseDateTime(date) }
        when "UNIX" # unix epoch
          parser = lambda { |date| org.joda.time.Instant.new((date.to_f * 1000).to_i).toDateTime }
        when "UNIX_MS" # unix epoch in ms
          parser = lambda { |date| org.joda.time.Instant.new(date.to_i).toDateTime }
        when "TAI64N" # TAI64 with nanoseconds, -10000 accounts for leap seconds
          parser = lambda do |date| 
            # Skip leading "@" if it is present (common in tai64n times)
            date = date[1..-1] if date[0, 1] == "@"

            org.joda.time.Instant.new((date[1..15].hex * 1000 - 10000)+(date[16..23].hex/1000000)).toDateTime 
          end
        else
          joda_parser = org.joda.time.format.DateTimeFormat.forPattern(format).withOffsetParsed
          if (locale != nil)
            joda_parser = joda_parser.withLocale(locale)
          end
          parser = lambda { |date| joda_parser.parseDateTime(date) }

          # Joda's time parser doesn't assume 'current time' for unparsed values.
          # That is, if you parse with format "mmm dd HH:MM:SS" (no year) then
          # the year is assumed to be unix epoch year, 1970, rather than
          # current year. This sucks, so try and keep track of fields that
          # are not specified so we can inject them later. (jordansissel)
          # LOGSTASH-34
          missing = DATEPATTERNS.reject { |p| format.include?(p) }
      end

      @logger.debug("Adding type with date config", :type => @type,
                    :field => field, :format => format)
      @parsers[field] << {
          :parser => parser,
          :missing => missing
      }
    end
  end

  # def register

  public
  def filter(event)
    @logger.debug("Date filter: received event", :type => event.type)
    return unless filter?(event)
    now = Time.now

    @parsers.each do |field, fieldparsers|
      @logger.debug("Date filter: type #{event.type}, looking for field #{field.inspect}",
                    :type => event.type, :field => field)
      # TODO(sissel): check event.message, too.
      next unless event.fields.member?(field)

      fieldvalues = event.fields[field]
      fieldvalues = [fieldvalues] if !fieldvalues.is_a?(Array)
      fieldvalues.each do |value|
        next if value.nil?
        begin
          time = nil
          missing = []
          success = false
          last_exception = RuntimeError.new "Unknown"
          fieldparsers.each do |parserconfig|
            parser = parserconfig[:parser]
            missing = parserconfig[:missing]
            #@logger.info :Missing => missing
            #p :parser => parser
            begin
              time = parser.call(value)
              success = true
              break # success
            rescue StandardError, JavaException => e
              last_exception = e
            end
          end # fieldparsers.each

          if !success
            raise last_exception
          end

          # Perform workaround for LOGSTASH-34
          if !missing.empty?
            # Inject any time values missing from the time parser format
            missing.each do |t|
              case t
              when "y"
                time = time.withYear(now.year)
              when "S"
                # TODO(sissel): Old behavior was to default to fractional sec == 0
                #time.setMillisOfSecond(now.usec / 1000)
                time = time.withMillisOfSecond(0)
              #when "Z"
                # Ruby 'time.gmt_offset' is in seconds.
                # timezone is missing, so let's add in our localtime offset.
                #time = time.plusSeconds(now.gmt_offset)
                # TODO(sissel): not clear if we need to do this...
              end # case t
            end
          end
          #@logger.info :JodaTime => time.to_s
          time = time.withZone(org.joda.time.DateTimeZone.forID("UTC"))
          event.timestamp = time.to_s 
          #event.timestamp = LogStash::Time.to_iso8601(time)
          @logger.debug("Date parsing done", :value => value, :timestamp => event.timestamp)
        rescue StandardError, JavaException => e
          @logger.warn("Failed parsing date from field", :field => field,
                       :value => value, :exception => e,
                       :backtrace => e.backtrace)
          # Raising here will bubble all the way up and cause an exit.
          # TODO(sissel): Maybe we shouldn't raise?
          # TODO(sissel): What do we do on a failure? Tag it like grok does?
          #raise e
        end # begin
      end # fieldvalue.each 
    end # @parsers.each

    filter_matched(event) if !event.cancelled?
    return event
  end # def filter
end # class LogStash::Filters::Date
