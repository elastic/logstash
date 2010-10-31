require "logstash/filters/base"
require "logstash/time"

class LogStash::Filters::Date < LogStash::Filters::Base
  # The 'date' filter will take a value from your event and use it as the
  # event timestamp. This is useful for parsing logs generated on remote
  # servers or for importing old logs.
  #
  # The config looks like this:
  #
  # filters:
  #   date:
  #     <tagname>:
  #       <fieldname>: <format>
  #     <tagname2>
  #       <fieldname>: <format>
  #
  # The format is whatever is supported by Ruby's DateTime.strptime
  def initialize(config = {})
    super

    @tags = Hash.new { |h,k| h[k] = [] }
  end # def initialize

  def register
    @config.each do |tag, tagconfig|
      @tags[tag] << tagconfig
    end # @config.each
  end # def register

  def filter(event)
    # TODO(sissel): crazy deep nesting here, refactor/redesign.
    return if event.tags.empty?
    event.tags.each do |tag|
      next unless @tags.include?(tag)
      @tags[tag].each do |tagconfig|
        tagconfig.each do |field, format|
          # TODO(sissel): check event.message, too.
          if (event.fields.include?(field) rescue false)
            fieldvalue = event.fields[field]
            fieldvalue = [fieldvalue] if fieldvalue.is_a?(String)
            fieldvalue.each do |value|
              #value = event["fields"][field]
              begin
                time = DateTime.strptime(value, format)
                event.timestamp = LogStash::Time.to_iso8601(time)
                @logger.debug "Parsed #{value.inspect} as #{event.timestamp}"
              rescue => e
                @logger.warn "Failed parsing date #{value.inspect} from field #{field} with format #{format.inspect}. Exception: #{e}"
              end
            end # fieldvalue.each 
          end # if this event has a field we expect to be a timestamp
        end # tagconfig.each
      end # @tags[tag].each
    end # event.tags.each
  end # def filter
end # class LogStash::Filters::Date
