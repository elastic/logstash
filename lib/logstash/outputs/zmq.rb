require "logstash/outputs/base"
require "logstash/namespace"
require "ffi-rzmq"
require "logstash/zmq_manager"


# Write events over a 0MQ socket
#
# Each event json is separated by a newline.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Outputs::Zmq < LogStash::Outputs::Base

  config_name "zmq"

  config :socket_addresses, :validate => :array, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "client"

  # ZMQ socket type, currently only PUSH is supported (but others might work!)
  config :socket_type, :validate => :string, :default => "push"

  # High watermark, amount of messages to keep in memory when unable to send
  config :hwm, :validate => :number, :default => 100
  # Disk swap of messages, same as HWM but on disk
  config :swap, :validate => :number, :default => 0
  # Time to wait before dispairing and dropping messages when terminating and there are still unsent messages
  config :linger, :validate => :number, :default => -1

  flag("--threads THREADS", "Number of ZeroMQ threads to spawn") do |val|
    ::LogStash::ZMQManager.threads = val.to_i
  end

  public
  def register
    @logger.info("Starting 0mq output", :socket_addresses => @socket_addresses)
    @socket = ::LogStash::ZMQManager.socket ::ZMQ.const_get socket_type.upcase
    @socket_addresses.each do |addr|
      if server?
        @logger.info("Binding socket", :address => addr)
        @socket.bind addr
      else
        @logger.info("Connecting socket", :address => addr)
        @socket.connect addr
      end
    end
    @socket.setsockopt ::ZMQ::HWM, @hwm
    @socket.setsockopt ::ZMQ::SWAP, @swap
    @socket.setsockopt ::ZMQ::LINGER, @linger
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
  def receive(event)
    return unless output?(event)

    wire_event = event.to_hash.to_json + "\n"

    begin
      @socket.send_string(event.to_hash.to_json)
    rescue => e
      @logger.warn("0mq output exception", :address => address,
                    :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
  
end # class LogStash::Outputs::Tcp
