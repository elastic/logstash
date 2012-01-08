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

  public
  def register
    @socket = ::LogStash::ZMQManager.socket ::ZMQ.const_get @socket_type.upcase
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
      message = String.new
      @socket.recv_string message
      e = to_event message, "0mq"
      @logger.debug("Got message from socket", :event => e)
      output_queue << e
    end # loop
  end # def run
end # class LogStash::Inputs::Tcp
