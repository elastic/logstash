require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/time" # should really use the filters/date.rb bits
require "socket"

# Read gelf messages as events over the network.
#
# This input is a good choice if you already use graylog2 today.
#
# The main reasoning for this input is to leverage existing GELF
# logging libraries such as the gelf log4j appender
#
class LogStash::Inputs::Gelf < LogStash::Inputs::Base
  config_name "gelf"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 12201

  # Whether or not to remap the gelf message fields
  # to logstash event fields or leave them
  # intact.
  # Remapping converts the following:
  # full_message => event.message
  # host => event.source_host ##NYI as event.source_host cannot be set here
  # file => event.source_path ##NYI as event.source_path cannot be set here
  #
  # Original message is parsed properly into event.fields
  config :remap, :validate => :boolean, :default => false

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true

    # nothing else makes sense here
    # gelf messages ARE json
    @format = ["json"]
  end # def initialize

  public
  def register
    require 'gelfd'
  end # def register

  public
  def run(output_queue)
    # udp server
    Thread.new do
      LogStash::Util::set_thread_name("input|gelf")
      begin
        udp_listener(output_queue)
      rescue => e
        @logger.warn("gelf listener died: #{$!}")
        @logger.debug(["Backtrace", e.backtrace])
        sleep(5)
        retry
      end # begin
    end # Thread.new
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting gelf listener on #{@host}:#{@port}")

    if @udp
      @udp.close_read
      @udp.close_write
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    loop do
      line, client = @udp.recvfrom(8192)
      # Ruby uri sucks, so don't use it.
      source = "gelf://#{client[3]}/"
      data = Gelfd::Parser.parse(line)
      # The nil guard is needed
      # to deal with chunked messages.
      # Gelfd::Parser.parse will only return the message
      # when all chunks are completed
      e = to_event(data, source) unless data.nil?
      if e
        remap_gelf(e) if @remap
        output_queue << e
      end
    end
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def udp_listener

  private
  def remap_gelf(event)
    event.message = event.fields["full_message"]
    # Neither event.data, event.source_host or event.source_path are expose with setters
    # For now, we'll just remap the full_message
    ##event.data["@source_host"] = event.fields["host"]
    ##event.data["@source_path"] = event.fields["file"]
  end # def remap_gelf
end # class LogStash::Inputs::Gelf
