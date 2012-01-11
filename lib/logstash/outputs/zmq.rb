require "logstash/outputs/base"
require "logstash/namespace"
require "ffi-rzmq"
require "logstash/util/zmq"


# Write events to a 0MQ PUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a publisher connecting to a subscriber
# bound to tcp://127.0.0.1:2120
#
class LogStash::Outputs::Zmq < LogStash::Outputs::Base

  config_name "zmq"
  plugin_status "experimental"

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq topic (Used with ZMQ_SUBSCRIBE, see http://api.zeromq.org/2-1:zmq-setsockopt 
  # for 'ZMQ_SUBSCRIBE: Establish message filter')
  config :queue, :validate => :string, :default => ""

  # Whether to bind ("server") or connect ("client") to the socket
  config :mode, :validate => [ "server", "client"], :default => "server"

  public
  def register
    # Unfortunately it's not possible to simply include at the class level
    # because the Config mixin thinks we're the included module and not the base-class
    self.class.send(:include, LogStash::Util::Zmq)
    @publisher = context.socket(ZMQ::PUB)
    error_check(@publisher.setsockopt(ZMQ::SUBSCRIBE, @queue)) if @queue != ""
    error_check(@publisher.setsockopt(ZMQ::LINGER, 1))
    setup(@publisher, @address)
  end # def register

  public
  def teardown
    error_check(@publisher.close)
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
      error_check(@publisher.send_string(wire_event))
    rescue => e
      @logger.warn("0mq output exception", :address => @address, :queue => @queue, :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::Zmq
