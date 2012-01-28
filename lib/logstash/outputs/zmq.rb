require "logstash/outputs/base"
require "logstash/namespace"


# Write events over a 0MQ socket
#
# Each event json is separated by a newline.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Outputs::Zmq < LogStash::Outputs::Base

  config_name "zmq"
  plugin_status "experimental"

  config :socket_addresses, :validate => :array, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "client"

  # ZMQ socket type, currently only PUSH and PUB are supported (but others might work!)
  config :socket_type, :validate => :string, :default => "push"

  # High watermark, amount of messages to keep in memory when unable to send
  config :hwm, :validate => :number, :default => 100
  # Disk swap of messages, same as HWM but on disk
  config :swap, :validate => :number, :default => 0
  # Time to wait before dispairing and dropping messages when terminating and there are still unsent messages
  config :linger, :validate => :number, :default => 1

  # PUB/SUB topic, can be an sprintf string for dynamic per event topic, E.G. "%{@type}"
  config :pubsub_topic, :validate => :string, :default => "logstash"

  # message format, an sprintf string. If ommited json_event will be used
  config :message_format, :validate => :string

  flag("--threads THREADS", "Number of ZeroMQ threads to spawn") do |val|
    ::LogStash::ZMQManager.threads = val.to_i
  end

  public
  def register
    require "ffi-rzmq"
    require "logstash/zmq_manager"
    @logger.info("Starting 0mq output", :socket_addresses => @socket_addresses)
    @socket_type = @socket_type.upcase.to_sym
    open_sockets
  end # def register

  def teardown
    @socket.close
    finished
  end

  def reload
    @socket.close
    open_sockets
  end

  private
  def open_sockets
    @socket = ::LogStash::ZMQManager.socket ::ZMQ.const_get @socket_type
    @socket_addresses.each do |addr|
      if server?
        @logger.info("Binding socket", :address => addr)
        @socket.bind addr
      else
        @logger.info("Connecting socket", :address => addr)
        @socket.connect addr
      end
    end
    assert(@socket.setsockopt(::ZMQ::HWM, @hwm), "Failed to set to set HWM")
    assert(@socket.setsockopt(::ZMQ::SWAP, @swap), "Failed to set SWAP size")
    assert(@socket.setsockopt(::ZMQ::LINGER, @linger) , "Failed to set socket linger time")
  end

  # parse the topic pattern
  def topic(e)
    e.sprintf(@pubsub_topic)
  end

  def server?
    @mode == "server"
  end # def server?

  def assert(val, msg)
    unless val == 0
      raise RuntimeError, "ZMQ error #{ZMQ::Util.error_string}. #{msg}"
    end
  end

  public
  def receive(event)
    return unless output?(event)

    event_text = if @message_format
      event.sprintf(@message_format) + "\n"
    else
      event.to_json
    end

    begin
      case @socket_type
      when :PUB
        assert(@socket.send_string(topic(event), ::ZMQ::SNDMORE), "Failed to send event")
      when :PUSH
        # nothing really
      end
      assert(@socket.send_string(event_text), "Failed to send event")
    rescue => e
      @logger.warn("0mq output exception", :socket_addresses => @socket_addresses,
                    :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
  
end # class LogStash::Outputs::Tcp
