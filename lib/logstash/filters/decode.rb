require 'logstash/namespace'
require 'logstash/filters/base'

# Decode filter. Applies a codec in decode mode to the specified event field
class LogStash::Filters::Decode < LogStash::Filters::Base

  config_name 'decode'
  milestone   1

  # Set the codec to apply
  #
  #     codec => some_codec { ... }
  #
  # For example, to decode JSON from the "message" field:
  #
  # filter {
  #   decode {
  #     codec => json { }
  #   }
  # }

  config :codec,  :validate => :codec,  :required => true

  # Set the source field (field to decode from).
  # Default: message
  #
  #     source => source_field
  #
  # For example, to decode JSON from the "data" field:
  #
  # filter {
  #   decode {
  #     codec  => json { }
  #     source => "data"
  #   }
  # }

  config :source, :validate => :string, :default  => 'message'

  # Set the target for storing the decoded data.
  # Default: message
  #
  #     target => some_field
  #
  # For example, to decode JSON into into the "data" field:
  #
  # filter {
  #   decode {
  #     codec  => json { }
  #     target => "data"
  #   }
  # }
  #
  # Note: The target field will be overwritten if present.

  config :target, :validate => :string, :default => 'message'

  def register
  end # def register

  def filter(event)
    return unless filter?(event)

    ctx         = @logger.context
    ctx[:codec] = @codec
    @logger.debug? && @logger.debug('Decode filter: decoding event', :source => @source, :target => @target)

    begin
      @codec.decode(event[@source]) do |ev|
        event[@target] = ev['message']
      end

      @logger.debug? && @logger.debug('Decode filter: decoded event')
      filter_matched(event)
    rescue => e
      event.tag('_decodefailure')
      @logger.warn('Trouble decoding', :source => @source, :raw => event[@source], :exception => e)
    end

    @logger.debug? && @logger.debug('Event after decoding', :event => event)
    ctx.clear

  end # def filter

  public :register, :filter

end # class LogStash::Filters::Decode

