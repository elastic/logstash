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
  # as each we use a context per thread.
  # By default, inputs bind/listen
  # and outputs connect
  config :address, :validate => :array, :default => ["tcp://*:2120"]

  # 0mq topology
  # The default logstash topologies work as follows:
  # * pushpull - inputs are pull, outputs are push
  # * pubsub - inputs are subscribers, outputs are publishers
  # * pair - inputs are clients, inputs are servers
  #
  # If the predefined topology flows don't work for you,
  # you can change the 'mode' setting
  # TODO (lusis) add req/rep MAYBE
  # TODO (lusis) add router/dealer
  config :topology, :validate => ["pushpull", "pubsub", "pair"]

  # 0mq topic
  # This is used for the 'pubsub' topology only
  # On inputs, this allows you to filter messages by topic
  # On outputs, this allows you to tag a message for routing
  # NOTE: ZeroMQ does subscriber side filtering.
  # NOTE: All topics have an implicit wildcard at the end
  config :topic, :validate => :string, :default => ""

  # mode
  # server mode binds/listens
  # client mode connects
  config :mode, :validate => ["server", "client"], :default => "server"

  # 0mq socket options
  # This exposes zmq_setsockopt
  # for advanced tuning
  # see http://api.zeromq.org/2-1:zmq-setsockopt for details
  #
  # This is where you would set values like:
  # ZMQ::HWM - high water mark
  # ZMQ::IDENTITY - named queues
  # ZMQ::SWAP_SIZE - space for disk overflow
  # ZMQ::SUBSCRIBE - topic filters for pubsub
  #
  # example: sockopt => ["ZMQ::HWM", 50, "ZMQ::IDENTITY", "my_named_queue"]
  config :sockopt, :validate => :hash

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    @format ||= "json_event"
    self.class.send(:include, LogStash::Util::ZeroMQ)

    case @topology
    when "pair"
      zmq_const = ZMQ::PAIR 
    when "pushpull"
      zmq_const = ZMQ::PULL
    when "pubsub"
      zmq_const = ZMQ::SUB
    end # case socket_type
    @zsocket = context.socket(zmq_const)

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    if @sockopt
      setopts(@zsocket, @sockopt)
    end

    setopts(@zsocket, {"ZMQ::SUBSCRIBE" => @topic}) if @topology == "pubsub"

    @address.each do |addr|
      setup(@zsocket, addr)
    end
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
        if @topology == "pubsub"
          topic = ''
          rc = @zsocket.recv_string(topic)
          error_check(rc, "in recv_string")
          @logger.debug("0mq input: got topic #{topic}")
        end
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
