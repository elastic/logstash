require "logstash/inputs/base"
require "logstash/namespace"

# Read events over a 0MQ socket
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Zmq < LogStash::Inputs::Base

  config_name "zmq"
  plugin_status "experimental"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :socket_addresses, :validate => :array, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  # Currently only PULL and SUB are supported, other socket types might work as well
  config :socket_type, :validate => :string, :default => "pull"

  # PUB/SUB topics to subscribe
  config :pubsub_topics, :validate => :array, :default => ["logstash"]

  config :format, :validate => ["json", "json_event", "plain"], :default => "json_event"

  flag("--threads THREADS", "Number of ZeroMQ threads to spawn") do |val|
    ::LogStash::ZMQManager.threads = val.to_i
  end

  public
  def register
    require "logstash/zmq_manager"
    require "ffi-rzmq"
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
    case @socket_type
    when :SUB
      @pubsub_topics.each do |topic|
        assert(@socket.setsockopt(::ZMQ::SUBSCRIBE, topic), "Failed to set socket topic")
      end
    when :PULL
      # nothing really.
    end
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
  def run(output_queue)
    @logger.info("Starting 0mq output", :address => @socket_address)
    @socket_addresses.each do |addr|
      if server?
        @logger.info("Binding socket", :address => addr)
        assert(@socket.bind(addr), "Failed to bind to #{addr}")
      else
        @logger.info("Connecting socket", :address => addr)
        assert(@socket.connect(addr), "Failed connecting to #{addr}")
      end
    end
    loop do
      message = Array.new
      assert(@socket.recv_strings(message), "Failed to recv message")
      if message.count > 1 and @socket_type == :SUB
        topic = message.first 
        e = to_event message[1..-1].join("\n"), "0mq"
      else
        topic = nil
        e = to_event message.join("\n"), "0mq"
      end
      # TODO (avishai): do we need to read the sender identity off the final frame?
      e['@zmq_topic'] = topic if topic and e
      @logger.debug("Got message from socket", :event => e, :topic => topic)
      output_queue << e
    end # loop
  end # def run
end # class LogStash::Inputs::Tcp
