require "logstash/inputs/base"
require "logstash/namespace"
require "ffi-rzmq"
require "timeout"
require "logstash/util/zmq"

# Read events over a 0MQ SUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a subscriber binding to tcp://127.0.0.1:2120 
# waiting for connecting publishers.
#
class LogStash::Inputs::Zmq < LogStash::Inputs::Base

  config_name "zmq"

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq queue size
  config :queue_size, :validate => :number, :default => 1000

  # 0mq topic to subscribe to
  config :queue, :validate => :string, :default => "" # default all

  # wether to bind ("server") or connect ("client") to the socket
  config :mode, :validate => [ "server", "client"], :default => "client"

  @source = "0mq_#{@address}/#{@queue}"

  public
  def register
    self.class.send(:include, LogStash::Util::Zmq)
    @subscriber = context.socket(ZMQ::SUB)
    error_check(@subscriber.setsockopt(ZMQ::HWM, @queue_length))
    error_check(@subscriber.setsockopt(ZMQ::SUBSCRIBE, @queue))
    error_check(@subscriber.setsockopt(ZMQ::LINGER, 1))
    setup(@subscriber, @address)
  end # def register

  def teardown
    error_check(@subscriber.close)
  end # def teardown

  def server?
    @mode == "server"
  end # def server?

  def run(output_queue)
    begin
      loop do
        msg = ''
        rc = @subscriber.recv_string(msg)
        error_check(rc)
        @logger.debug("0mq: receiving", :event => msg)
        e = self.to_event(msg, @source)
        if e
          output_queue << e
        end
      end
    rescue => e
      @logger.debug("ZMQ Error", :subscriber => @subscriber,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Read timeout", subscriber => @subscriber)
    end # begin
  end # def run
end # class LogStash::Inputs::Zmq
