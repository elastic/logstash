# encoding: utf-8
require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/json"
require "logstash/timestamp"
require "socket"

# This input will read GELF messages as events over the network,
# making it a good choice if you already use Graylog2 today.
#
# The main use case for this input is to leverage existing GELF
# logging libraries such as the GELF log4j appender.
#
class LogStash::Inputs::Gelf < LogStash::Inputs::Base
  config_name "gelf"
  milestone 2

  default :codec, "plain"

  # The IP address or hostname to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 12201

  # Whether or not to remap the GELF message fields to Logstash event fields or
  # leave them intact.
  #
  # Remapping converts the following GELF fields to Logstash equivalents:
  #
  # * `full\_message` becomes event["message"].
  # * if there is no `full\_message`, `short\_message` becomes event["message"].
  config :remap, :validate => :boolean, :default => true

  # Whether or not to remove the leading '\_' in GELF fields or leave them
  # in place. (Logstash < 1.2 did not remove them by default.). Note that
  # GELF version 1.1 format now requires all non-standard fields to be added
  # as an "additional" field, beginning with an underscore.
  #
  # e.g. `\_foo` becomes `foo`
  #
  config :strip_leading_underscore, :validate => :boolean, :default => true

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
    require 'gelfd'
    @udp = nil
  end # def register

  public
  def run(output_queue)
    begin
      # udp server
      udp_listener(output_queue)
    rescue => e
      @logger.warn("gelf listener died", :exception => e, :backtrace => e.backtrace)
      sleep(5)
      retry
    end # begin
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting gelf listener", :address => "#{@host}:#{@port}")

    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    while true
      line, client = @udp.recvfrom(8192)
      begin
        data = Gelfd::Parser.parse(line)
      rescue => ex
        @logger.warn("Gelfd failed to parse a message skipping", :exception => ex, :backtrace => ex.backtrace)
        next
      end

      # Gelfd parser outputs null if it received and cached a non-final chunk
      next if data.nil?

      event = LogStash::Event.new(LogStash::Json.load(data))
      event["source_host"] = client[3]
      if event["timestamp"].is_a?(Numeric)
        event.timestamp = LogStash::Timestamp.at(event["timestamp"])
        event.remove("timestamp")
      end
      remap_gelf(event) if @remap
      strip_leading_underscore(event) if @strip_leading_underscore
      decorate(event)
      output_queue << event
    end
  rescue LogStash::ShutdownSignal
    # Do nothing, shutdown.
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def udp_listener

  private
  def remap_gelf(event)
    if event["full_message"]
      event["message"] = event["full_message"].dup
      event.remove("full_message")
      if event["short_message"] == event["message"]
        event.remove("short_message")
      end
    elsif event["short_message"]
      event["message"] = event["short_message"].dup
      event.remove("short_message")
    end
  end # def remap_gelf

  private
  def strip_leading_underscore(event)
     # Map all '_foo' fields to simply 'foo'
     event.to_hash.keys.each do |key|
       next unless key[0,1] == "_"
       event[key[1..-1]] = event[key]
       event.remove(key)
     end
  end # deef removing_leading_underscores
end # class LogStash::Inputs::Gelf
