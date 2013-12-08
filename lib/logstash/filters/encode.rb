require 'logstash/namespace'
require 'logstash/filters/base'

# Encode filter. Applies a codec in encode mode to the specified event field
class LogStash::Filters::Encode < LogStash::Filters::Base

  config_name 'encode'
  milestone   1

  # Set the codec to apply
  #
  #     codec => some_codec { ... }
  #
  # For example, to encode the "message" field as JSON:
  #
  # filter {
  #   encode {
  #     codec => json { }
  #   }
  # }

  config :codec,  :validate => :codec,  :required => true

  # Set the source field (field to encode from).
  # Default: message
  #
  #     source => source_field
  #
  # For example, to encode the "data" field as JSON:
  #
  # filter {
  #   encode {
  #     codec  => json { }
  #     source => "data"
  #   }
  # }

  config :source, :validate => :string, :default  => 'message'

  # Set the target for storing the encoded data.
  # Default: message
  #
  #     target => some_field
  #
  # For example, to encode JSON into into the "data" field:
  #
  # filter {
  #   encode {
  #     codec  => json { }
  #     target => "data"
  #   }
  # }
  #
  # Note: The target field will be overwritten if present.

  config :target, :validate => :string, :default  => 'message'

  def register
    @codec.on_event{ |payload| payload }
  end # def register

  def filter(event)
    return unless filter?(event)

    ctx         = @logger.context
    ctx[:codec] = @codec
    @logger.debug? && @logger.debug('Encode filter: encoding event', :source => @source, :target => @target)

    begin
      event[@target] = @codec.encode(event[@source])
      @logger.debug? && @logger.debug('Encode filter: encoded event')
      filter_matched(event)
    rescue => e
      event.tag('_encodefailure')
      @logger.warn('Trouble encoding', :source => @source, :raw => event[@source], :exception => e)
    end

    @logger.debug? && @logger.debug('Event after encoding', :event => event)
    ctx.clear
  end # def filter

  public :register, :filter

end # class LogStash::Filters::Encode

