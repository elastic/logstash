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

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq queue size
  config :queue_size, :validate => :number, :default => 20

  # 0mq topic (Used with ZMQ_SUBSCRIBE, see http://api.zeromq.org/2-1:zmq-setsockopt 
  # for 'ZMQ_SUBSCRIBE: Establish message filter')
  config :queue_name, :validate => :string, :default => "" # default all

  # 0mq socket type
  # There is no default.
  config :socket_type, :validate => ["req","pull","sub","dealer","pair"], :required => true

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
  # server mode binds
  # client mode connects
  # This only makes sense with "pair" types
  config :mode, :validate => ["server", "client"], :default => "client"

  @source = "0mq_#{@address}/#{@queue}"

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)
    case @socket_type
    when "req"
      zmq_const = ZMQ::REQ
      @mode = "client"
    when "pair"
      zmq_const = ZMQ::PAIR
      @mode ||= "server"
    when "pull"
      zmq_const = ZMQ::PULL
      @mode = "client"
    when "sub"
      zmq_const = ZMQ::SUB
      @mode = "client"
    end
    @zsocket = context.socket(zmq_const)
    error_check(@zsocket.setsockopt(ZMQ::HWM, @queue_size),
                "while setting ZMQ:HWM == #{@queue_size.inspect}")
    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")
    error_check(@zsocket.setsockopt(ZMQ::SWAP, @swap_size),
                "while setting ZMQ::SWAP == #{@swap_size}")
    if @socket_type == "sub"
      error_check(@zsocket.setsockopt(ZMQ::SUBSCRIBE, @queue_name),
                  "while setting ZMQ:SUBSCRIBE == #{@queue.inspect}")
    end

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
