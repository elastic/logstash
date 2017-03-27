require "logstash/filters/base"
require "logstash/namespace"

# This filter parses events from CloudFront log files.
# It can possibly handle other W3C extended log format files
# but it doesn't encompass the full specification.
#
# When used in conjuction with the S3 input plugin,
# it automatically uses the Fields metadata set in the log file.
class LogStash::Filters::CloudFront < LogStash::Filters::Base
  config_name "cloudfront"
  milestone 1

  # The format used to parse the message.
  # Example: date time sc-bytes c-ip cs-method cs(Host) sc-status cs(Referer) cs(User-Agent) cs-uri-query
  # Non-matching lines will be discarded.
  #
  # If unset, it looks for the "cloudfront_fields" field set by the S3 input plugin.
  # If that doesn't exist either, it discards the event.
  config :format, :validate => :string, :default => nil

  # Whether to remove the CloudFront metadata set by the S3 plugin.
  # Defaults to true to save space as it's usually just for internal use.
  config :remove_metadata, :validate => :boolean, :default => true

  public
  def register
    LogStash::Util::set_thread_name("filter|cloudfront");
    @logger.info("Registering cloudfront filter")
    if @format.nil?
        @default_format = nil
    else
        @default_format = @format.split()
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    event_format = @default_format
    if event_format.nil?
      unless  event["cloudfront_fields"].nil?
        event_format =  event["cloudfront_fields"].split()
      end
    end

    if event_format.nil?
      @logger.debug("No format found, discarding event")
      event.cancel()
    else
      message = event["message"].strip().split("\t")
      if (message.length() != event_format.length())
        @logger.debug("Event doesn't match format, discarding event")
        event.cancel()
      else
        if @remove_metadata
          event.remove("cloudfront_version")
          event.remove("cloudfront_fields")
        end
        message.each_index do |i|
          unless message[i] == "-"
            event[event_format[i]] = message[i]
          end
        end
      end
    end
    filter_matched(event) if !event.cancelled?
    # Trying to debug what's wrong
    @logger.debug("Event after cloudfront filter", :event => event)
  end # def filter

end # class LogStash::Filters::CloudFront
