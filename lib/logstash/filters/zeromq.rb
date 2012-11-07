require "logstash/filters/base"
require "logstash/namespace"

# ZeroMQ filter. This is the best way to send an event externally for filtering
# It works much like an exec filter would by sending the event "offsite"
# for processing and waiting for a response
#
# The protocol here is:
#   * REQ sent with JSON-serialized logstash event
#   * REP read expected to be the full JSON 'filtered' event
#   * - if reply read is an empty string, it will cancel the event.
#
# Note that this is a limited subset of the zeromq functionality in
# inputs and outputs. The only topology that makes sense here is:
# REQ/REP. 
class LogStash::Filters::ZeroMQ < LogStash::Filters::Base

  config_name "zeromq"
  plugin_status "experimental"

  # 0mq socket address to connect or bind
  # Please note that inproc:// will not work with logstash
  # as we use a context per thread
  # By default, filters connect
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2121"

  # The field to send off-site for processing
  # If this is unset, the whole event will be sent
  # TODO (lusis)
  # Allow filtering multiple fields
  config :field, :validate => :string

  # 0mq mode
  # server mode binds/listens
  # client mode connects
  config :mode, :validate => ["server", "client"], :default => "client"

  
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
  def initialize(params)
    super(params)

    @threadsafe = false
  end

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)

    @zsocket = context.socket(ZMQ::REQ)

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    if @sockopt
      setopts(@zsocket, @sockopt)
    end

    setup(@zsocket, @address)
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    # TODO (lusis)
    # Need to set a timeout on the socket
    # If it never gets a reply, filtering stops cold
    begin
      if @field
        @logger.debug("0mq: sending", :request => event[@field])
        error_check(@zsocket.send_string(event[@field]), "in send_string")
      else
        @logger.debug("0mq: sending", :request => event.to_json)
        error_check(@zsocket.send_string(event.to_json), "in send_string")
      end
      reply = ''
      rc = @zsocket.recv_string(reply)
      error_check(rc, "in recv_string")

      # If we receive an empty reply, this is an indication that the filter
      # wishes to cancel this event.
      if reply.empty?
        event.cancel
        return
      end
      @logger.debug("0mq: receiving", :reply => reply)
      if @field
        event[@field] = event.sprintf(reply)
        filter_matched(event)
      else
        reply = JSON.parse(reply)
        event.overwrite(reply)
      end
      filter_matched(event)
    rescue => e
      @logger.warn("0mq filter exception", :address => @address, :exception => e, :backtrace => e.backtrace)
    end
  end # def filter

  private
  def server?
    @mode == "server"
  end # def server?

end # class LogStash::Filters::ZeroMQ
