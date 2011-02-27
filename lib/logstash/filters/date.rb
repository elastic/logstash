require "logstash/filters/base"
require "logstash/namespace"
require "logstash/time"
require "java"

class LogStash::Filters::Date < LogStash::Filters::Base

  config_name "date"

  # Config for date is:
  #   fieldname: dateformat
  #   Allow arbitrary keys for this config.
  config /[A-Za-z0-9_-]+/, :validate => :string

  # LOGSTASH-34
  DATEPATTERNS = %w{ y d H m s S Z }

  # The 'date' filter will take a value from your event and use it as the
  # event timestamp. This is useful for parsing logs generated on remote
  # servers or for importing old logs.
  #
  # The config looks like this:
  #
  # filters {
  #   date {
  #     type => "typename"
  #     fielname => fieldformat
  #
  #     # Example:
  #     timestamp => "mmm DD HH:mm:ss"
  #   }
  # }
  #
  # The format is whatever is supported by Joda; generally:
  # http://download.oracle.com/javase/1.4.2/docs/api/java/text/SimpleDateFormat.html
  public
  def initialize(config = {})
    super

    @parsers = Hash.new { |h,k| h[k] = [] }
  end # def initialize

  public
  def register
    #@formatter = org.joda.time.format.DateTimeFormat.forPattern
    @config.each do |fieldname, value|
      next if fieldname == "type"

      @logger.debug "Adding type #{@type} with date config: #{fieldname} => #{value}"
      @parsers[fieldname] << {
        :parser  => org.joda.time.format.DateTimeFormat.forPattern(value).withOffsetParsed(),

        # Joda's time parser doesn't assume 'current time' for unparsed values.
        # That is, if you parse with format "mmm dd HH:MM:SS" (no year) then
        # the year is assumed to be unix epoch year, 1970, rather than
        # current year. This sucks, so try and keep track of fields that
        # are not specified so we can inject them later. (jordansissel)
        # LOGSTASH-34
        :missing => DATEPATTERNS.reject { |p| value.include?(p) }
      }


    end # @config.each
  end # def register

  public
  def filter(event)
    @logger.debug "DATE FILTER: received event of type #{event.type}"
    return unless event.type == @type
    now = Time.now

    @parsers.each do |field, fieldparsers|

      @logger.debug "DATE FILTER: type #{event.type}, looking for field #{field.inspect}"
      # TODO(sissel): check event.message, too.
      next unless event.fields.member?(field)

      fieldvalues = event.fields[field]
      fieldvalues = [fieldvalues] if fieldvalues.is_a?(String)
      fieldvalues.each do |value|
        next if value.nil? or value.empty?
        begin
          time = nil
          missing = []
          fieldparsers.each do |parserconfig|
            parser = parserconfig[:parser]
            missing = parserconfig[:missing]
            @logger.info :Missing => missing
            time = parser.parseMutableDateTime(value)
            break # TODO(sissel): do something else
          end # fieldparsers.each

          # Perform workaround for LOGSTASH-34
          if !missing.empty?
            # Inject any time values missing from the time parser format
            missing.each do |t|
              case t
              when "y"
                time.setYear(now.year)
              when "S"
                time.setMillisOfSecond(now.usec / 1000)
              when "Z"
                # TODO(sissel): Implement
                # time.setZone( some DateTimeZone class? )
              end # case t
            end
          end
          @logger.info :JodaTime => time.to_s
          event.timestamp = time.to_s 
          #event.timestamp = LogStash::Time.to_iso8601(time)
          @logger.debug "Parsed #{value.inspect} as #{event.timestamp}"
        rescue => e
          @logger.warn "Failed parsing date #{value.inspect} from field #{field}: #{e}"
          raise e
        end # begin
      end # fieldvalue.each 
    end # @parsers.each
  end # def filter
end # class LogStash::Filters::Date
