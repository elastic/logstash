require "logstash/outputs/base"
require "logstash/namespace"

# Write events to a 0MQ PUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a publisher connecting to a subscriber
# bound to tcp://127.0.0.1:2120
#
class LogStash::Outputs::ZeroMQ < LogStash::Outputs::Base

  config_name "zeromq"
  plugin_status "experimental"

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq queue size
  config :queue_size, :validate => :number, :default => 20

  # 0mq topic (Used with ZMQ_SUBSCRIBE, see http://api.zeromq.org/2-1:zmq-setsockopt 
  # for 'ZMQ_SUBSCRIBE: Establish message filter')
  config :queue_name, :validate => :string, :default => ""

  # 0mq socket type
  # There is no default.
  config :socket_type, :validate => ["rep","push","pub","router","pair"], :required => true

  # 0mq swap size
  # Controls buffering to disk 
  # in the event of messages counts exceeding the queue_size
  # size in bytes
  # Default: 15MB
  # (ZMQ_SWAP)
  config :swap_size, :validate => :number, :default => 15728640

  # 0mq identity
  # (ZMQ_IDENTITY)
  config :identity, :validate => :string

  # 0mq socket options
  # This exposes zmq_setsockopt
  # for advanced tuning
  # see http://api.zeromq.org/2-1:zmq-setsockopt for details
  config :sockopt, :validate => :hash

  # mode
  # server mode binds/listens
  # client mode connects
  # This only makes sense with "pair" types
  # default pair mode is server
  config :mode, :validate => [ "server", "client"], :default => "server"

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)
    case @socket_type
    when "rep"
      zmq_const = ZMQ::REP
      @mode = "server"
    when "pair"
      zmq_const = ZMQ::PAIR
      @mode ||= "client"
    when "push"
      zmq_const = ZMQ::PUSH
      @mode = "server"
    when "pub"
      zmq_const = ZMQ::PUB
      @mode = "server"
    end
    @zsocket = context.socket(zmq_const)
    error_check(@zsocket.setsockopt(ZMQ::HWM, @queue_size),
                "while setting ZMQ:HWM == #{@queue_size.inspect}")
    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")
    error_check(@zsocket.setsockopt(ZMQ::SWAP, @swap_size),
                "while setting ZMQ::SWAP == #{@swap_size}")
    setup(@zsocket, @address)
  end # def register

  public
  def teardown
    error_check(@publisher.close, "while closing the socket")
  end # def teardown

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def receive(event)
    return unless output?(event)

    # TODO(sissel): Figure out why masterzen has '+ "\n"' here
    #wire_event = event.to_hash.to_json + "\n"
    wire_event = event.to_json

    begin
      @logger.debug("0mq: sending", :event => wire_event)
      error_check(@zsocket.send_string(wire_event), "in send_string")
    rescue => e
      @logger.warn("0mq output exception", :address => @address, :queue => @queue_name, :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::ZeroMQ
