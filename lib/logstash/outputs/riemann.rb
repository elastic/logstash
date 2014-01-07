# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Riemann is a network event stream processing system.
#
# While Riemann is very similar conceptually to Logstash, it has
# much more in terms of being a monitoring system replacement.
#
# Riemann is used in Logstash much like statsd or other metric-related
# outputs
#
# You can learn about Riemann here:
#
# * <http://riemann.io/>
# You can see the author talk about it here:
# * <http://vimeo.com/38377415>
#
class LogStash::Outputs::Riemann < LogStash::Outputs::Base
  config_name "riemann"
  milestone 1

  # The address of the Riemann server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect to on your Riemann server.
  config :port, :validate => :number, :default => 5555

  # The protocol to use
  # UDP is non-blocking
  # TCP is blocking
  #
  # Logstash's default output behaviour
  # is to never lose events
  # As such, we use tcp as default here
  config :protocol, :validate => ["tcp", "udp"], :default => "tcp"

  # The name of the sender.
  # This sets the `host` value
  # in the Riemann event
  config :sender, :validate => :string, :default => "%{host}"

  # A Hash to set Riemann event fields
  # (<http://riemann.io/concepts.html>).
  #
  # The following event fields are supported:
  # `description`, `state`, `metric`, `ttl`, `service`
  #
  # Tags found on the Logstash event will automatically be added to the
  # Riemann event.
  #
  # Any other field set here will be passed to Riemann as an event attribute.
  #
  # Example:
  #
  #     riemann {
  #         riemann_event => {
  #             "metric"  => "%{metric}"
  #             "service" => "%{service}"
  #         }
  #     }
  #
  # `metric` and `ttl` values will be coerced to a floating point value.
  # Values which cannot be coerced will zero (0.0).
  #
  # `description`, by default, will be set to the event message
  # but can be overridden here.
  config :riemann_event, :validate => :hash

  # If set to true automatically map all logstash defined fields to riemann event fields.
  # All nested logstash fields will be mapped to riemann fields containing all parent keys
  # separated by dots and the deepest value.
  #
  # As an example, the logstash event:
  #    {
  #      "@timestamp":"2013-12-10T14:36:26.151+0000",
  #      "@version": 1,
  #      "message":"log message",
  #      "host": "host.domain.com",
  #      "nested_field": {
  #                        "key": "value"
  #                      }
  #    }
  # Is mapped to this riemann event:
  #   {
  #     :time 1386686186,
  #     :host host.domain.com,
  #     :message log message,
  #     :nested_field.key value
  #   }
  #
  # It can be used in conjunction with or independent of the riemann_event option.
  # When used with the riemann_event any duplicate keys receive their value from
  # riemann_event instead of the logstash event itself.
  config :map_fields, :validate => :boolean, :default => false

  #
  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require 'riemann/client'
    @client = Riemann::Client.new(:host => @host, :port => @port)
  end # def register

  public
  def map_fields(parent, fields)
    fields.each {|key, val|
      if !key.start_with?("@")
        field = parent.nil? ? key : parent + '.' + key
        contents = val                            
        if contents.is_a?(Hash)                                     
          map_fields(field, contents)                                       
        else                                                                                  
          @my_event[field.to_sym] = contents                                                          
        end
      end
    }                 
  end

  public
  def receive(event)
    return unless output?(event)

    # Let's build us an event, shall we?
    r_event = Hash.new
    r_event[:host] = event.sprintf(@sender)
    # riemann doesn't handle floats so we reduce the precision here
    r_event[:time] = event["@timestamp"].to_i
    r_event[:description] = event["message"]
    if @riemann_event
      @riemann_event.each do |key, val|
        if ["ttl","metric"].include?(key)
          r_event[key.to_sym] = event.sprintf(val).to_f
        else
          r_event[key.to_sym] = event.sprintf(val)
        end
      end
    end
    if @map_fields == true
      @my_event = Hash.new
      map_fields(nil, event)
      r_event.merge!(@my_event) {|key, val1, val2| val1}
    end
    r_event[:tags] = event["tags"] if event["tags"].is_a?(Array)
    @logger.debug("Riemann event: ", :riemann_event => r_event)
    begin
      proto_client = @client.instance_variable_get("@#{@protocol}")
      @logger.debug("Riemann client proto: #{proto_client.to_s}")
      proto_client << r_event
    rescue Exception => e
      @logger.debug("Unhandled exception", :error => e)
    end
  end # def receive
end # class LogStash::Outputs::Riemann
