require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/zmq_manager"
require "ffi-rzmq"

# Read events over a 0MQ socket
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Zmq < LogStash::Inputs::Base

  config_name "zmq"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :socket_addresses, :validate => :array, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  config :socket_type, :validate => :string, :default => "pull"

  config :pubsub_topics, :validate => :array, :default => ["logstash"]

  config :format, :validate => ["json", "json_event", "plain"], :default => "json_event"

  flag("--threads THREADS", "Number of ZeroMQ threads to spawn") do |val|
    ::LogStash::ZMQManager.threads = val.to_i
  end

  public
  def register
    @socket_type = @socket_type.upcase.to_sym
    @socket = ::LogStash::ZMQManager.socket ::ZMQ.const_get @socket_type
    case @socket_type
    when :SUB
      @pubsub_topics.each do |topic|
        @socket.setsockopt ::ZMQ::SUBSCRIBE, topic
      end
    when :PULL
      # nothing really.
    end
  end # def register

  def teardown
    @socket.close
    finished
    ::LogStash::ZMQManager.terminate
  end

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def run(output_queue)
    @logger.info("Starting 0mq output", :address => @socket_address)
    @socket_addresses.each do |addr|
      if server?
        @logger.info("Binding socket", :address => addr)
        @socket.bind addr
      else
        @logger.info("Connecting socket", :address => addr)
        @socket.connect addr
      end
    end
    loop do
      message = Array.new
      @socket.recv_strings message
      if message.count > 1 and @socket_type == :SUB
        topic = message.first 
        e = to_event message[1, message.length].join("\n"), "0mq"
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
