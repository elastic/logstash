require "logstash/inputs/base"
require "logstash/namespace"
require "timeout"

# Read events over a 0MQ SUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a subscriber binding to tcp://127.0.0.1:2120 
# waiting for connecting publishers.
#
class LogStash::Inputs::ZeroMQ < LogStash::Inputs::Base

  config_name "zeromq"
  plugin_status "experimental"

  # 0mq socket address to connect or bind
  # Please note that `inproc://` will not work with logstash
  # As each we use a context per thread
  # To listen on all addresses, use `*` as the ip address
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq queue size
  config :queue_size, :validate => :number, :default => 20

  # 0mq topic (Used with ZMQ_SUBSCRIBE, see http://api.zeromq.org/2-1:zmq-setsockopt 
  # for 'ZMQ_SUBSCRIBE: Establish message filter')
  config :topic, :validate => :string, :default => "" # default all

  # 0mq message pattern
  # Instead of declaring socket_types in logstash,
  # we abstract this to a 'pattern':
  # This should cover most standard use cases
  # In the event that you need finer-grained control,
  # please use `socket_type` and not this option.
  # 
  # To control if this is a sender or receiver, please set `mode` below
  # TODO (lusis) fix req/rep
  config :pattern, :validate => ["pushpull", "pubsub", "pair", "reqrep"]

  # 0mq socket type
  # There is no default.
  # This setting conflicts with `pattern`
  # TODO (lusis) fix req/rep
  config :socket_type, :validate => ["req", "rep", "push", "pull", "sub", "pair"]

  # 0mq swap size
  # Controls buffering to disk 
  # in the event of messages counts exceeding the queue_size
  # size in bytes
  # Default: 15MB
  # (ZMQ_SWAP)
  config :swap_size, :validate => :number

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
  config :mode, :validate => ["server", "client"], :default => "client"

  @source = "0mq_#{@address}/#{@queue}"

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)
    if @pattern
      %w{socket_type}.each do |var|
        if instance_variable_get("@#{var}")
          @logger.error("inputs/zeromq: You cannot specify "\
                        "'pattern' and also set '#{var}'")
          raise "Invalid configuration detected. Please fix."
        end # if instance_variable_get
      end # socket_type each

      case @pattern
      when "pubsub"
        # Input with pubsub only makes sense as a subscriber
        @socket_type = "sub"
      when "pushpull"
        # Input with pushpull
        # We can either listen for events
        # or poll for events
        @mode == "client" ? (@socket_type = "pull") : (@socket_type = "push")
      when "pair"
        # Input with pair
        # We can either listen for events
        # or poll for them
        @socket_type = "pair"
      when "reqrep"
        # Input with reqrep
        # We can either listen or events
        # or poll for them
        @mode == "client" ? (@socket_type = "req") : (@socket_type = "rep")
      end # case pattern
    end # if pattern

    case @socket_type
    when "req"
      zmq_const = ZMQ::REQ
      @mode = "client" # req is by nature a client. it REQuests
    when "rep"
      zmq_const = ZMQ::REP
      @mode = "server" # rep is by nature a server. it REPlies
    when "pair"
      zmq_const = ZMQ::PAIR 
      @mode ||= "server" # pair can be either server or client.
    when "pull"
      zmq_const = ZMQ::PULL
      @mode = "client" # pull is by nature a client. 
    when "push"
      zmq_const = ZMQ::PUSH
      @mode = "server" # push is by nature a server
    when "sub"
      zmq_const = ZMQ::SUB
      @mode = "client" # sub is by nature a client
    end # case socket_type
    @zsocket = context.socket(zmq_const)
    error_check(@zsocket.setsockopt(ZMQ::HWM, @queue_size),
                "while setting ZMQ:HWM == #{@queue_size.inspect}")

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    if @swap_size
      error_check(@zsocket.setsockopt(ZMQ::SWAP, @swap_size),
                  "while setting ZMQ::SWAP == #{@swap_size.inspect}")
    end # if swap_size

    if @identity
      error_check(@zsocket.setsockopt(ZMQ::IDENTITY, @identity),
                  "while setting ZMQ::IDENTITY == #{@identity.inspect}")
    end # if identity

    if @socket_type == "sub"
      error_check(@zsocket.setsockopt(ZMQ::SUBSCRIBE, @topic),
                  "while setting ZMQ:SUBSCRIBE == #{@topic.inspect}")
    end # if sub

    setup(@zsocket, @address)
  end # def register

  def teardown
    error_check(@zsocket.close, "while closing the zmq socket")
  end # def teardown

  def server?
    @mode == "server"
  end # def server?

  def run(output_queue)
    begin
      loop do
        msg = ''
        rc = @zsocket.recv_string(msg)
        error_check(rc, "in recv_string")
        @logger.debug("0mq: receiving", :event => msg)
        e = self.to_event(msg, @source)
        if e
          output_queue << e
        end
      end
    rescue => e
      @logger.debug("ZMQ Error", :subscriber => @zsocket,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Read timeout", subscriber => @zsocket)
    end # begin
  end # def run
end # class LogStash::Inputs::ZeroMQ
