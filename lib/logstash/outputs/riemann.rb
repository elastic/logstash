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
# * <http://aphyr.github.com/riemann/>
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
  # (<http://aphyr.github.com/riemann/concepts.html>).
  #
  # The following event fields are supported:
  # `description`, `state`, `metric`, `ttl`, `service`
  #
  # Example:
  #
  #     riemann {
  #         riemann_event => [ 
  #             "metric", "%{metric}",
  #             "service", "%{service}"
  #         ]
  #     }
  #
  # `metric` and `ttl` values will be coerced to a floating point value. 
  # Values which cannot be coerced will zero (0.0).
  #
  # `description`, by default, will be set to the event message
  # but can be overridden here.
  config :riemann_event, :validate => :hash

  #
  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require 'riemann/client'
    @client = Riemann::Client.new(:host => @host, :port => @port)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    
    # Let's build us an event, shall we?
    r_event = Hash.new
    r_event[:host] = event.sprintf(@sender)
    # riemann doesn't handle floats so we reduce the precision here
    r_event[:time] = event.unix_timestamp.to_i
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
    r_event[:tags] = @tags if @tags
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
