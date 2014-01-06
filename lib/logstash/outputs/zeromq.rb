# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Write events to a 0MQ PUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this output plugin.
#
# The default settings will create a publisher connecting to a subscriber
# bound to tcp://127.0.0.1:2120
#
class LogStash::Outputs::ZeroMQ < LogStash::Outputs::Base

  config_name "zeromq"
  milestone 2

  default :codec, "json"

  # 0mq socket address to connect or bind.
  # Please note that `inproc://` will not work with logstashi.
  # For each we use a context per thread.
  # By default, inputs bind/listen and outputs connect.
  config :address, :validate => :array, :default => ["tcp://127.0.0.1:2120"]

  # The default logstash topologies work as follows:
  #
  # * pushpull - inputs are pull, outputs are push
  # * pubsub - inputs are subscribers, outputs are publishers
  # * pair - inputs are clients, inputs are servers
  #
  # If the predefined topology flows don't work for you,
  # you can change the 'mode' setting
  # TODO (lusis) add req/rep MAYBE
  # TODO (lusis) add router/dealer
  config :topology, :validate => ["pushpull", "pubsub", "pair"], :required => true

  # This is used for the 'pubsub' topology only.
  # On inputs, this allows you to filter messages by topic.
  # On outputs, this allows you to tag a message for routing.
  # NOTE: ZeroMQ does subscriber-side filtering
  # NOTE: Topic is evaluated with `event.sprintf` so macros are valid here.
  config :topic, :validate => :string, :default => ""

  # Server mode binds/listens. Client mode connects.
  config :mode, :validate => ["server", "client"], :default => "client"

  # This exposes zmq_setsockopt for advanced tuning.
  # See http://api.zeromq.org/2-1:zmq-setsockopt for details.
  #
  # This is where you would set values like:
  #
  # * ZMQ::HWM - high water mark
  # * ZMQ::IDENTITY - named queues
  # * ZMQ::SWAP_SIZE - space for disk overflow
  #
  # Example: sockopt => ["ZMQ::HWM", 50, "ZMQ::IDENTITY", "my_named_queue"]
  config :sockopt, :validate => :hash

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)

    if @mode == "server"
      workers_not_supported("With 'mode => server', only one zeromq socket may bind to a port and may not be shared among threads. Going to single-worker mode for this plugin!")
    end

    # Translate topology shorthand to socket types
    case @topology
    when "pair"
      zmq_const = ZMQ::PAIR
    when "pushpull"
      zmq_const = ZMQ::PUSH
    when "pubsub"
      zmq_const = ZMQ::PUB
    end # case socket_type

    @zsocket = context.socket(zmq_const)

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    if @sockopt
      setopts(@zsocket, @sockopt)
    end

    @address.each do |addr|
      setup(@zsocket, addr)
    end

    @codec.on_event(&method(:publish))
  end # def register

  public
  def teardown
    error_check(@zsocket.close, "while closing the socket")
  end # def teardown

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def receive(event)
    return unless output?(event)

    @codec.encode(event)
  end # def receive

  def publish(payload)
    @logger.debug? && @logger.debug("0mq: sending", :event => payload)
    if @topology == "pubsub"
      # TODO(sissel): Need to figure out how to fit this into the codecs system.
      #@logger.debug("0mq output: setting topic to: #{event.sprintf(@topic)}")
      #error_check(@zsocket.send_string(event.sprintf(@topic), ZMQ::SNDMORE),
                  #"in topic send_string")
    end
    error_check(@zsocket.send_string(payload), "in send_string")
  rescue => e
    @logger.warn("0mq output exception", :address => @address, :exception => e)
  end
end # class LogStash::Outputs::ZeroMQ
