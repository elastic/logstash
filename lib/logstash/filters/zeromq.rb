# encoding: utf-8
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
  milestone 1

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

  # timeout in milliseconds on which to wait for a reply.
  config :timeout, :validate => :number, :default => 500
  
  # number of retries, used for both sending and receiving messages.
  # for sending, retries should return instantly.
  # for receiving, the total blocking time is up to retries X timeout, 
  # which by default is 3 X 500 = 1500ms
  config :retries, :validate => :number, :default => 3

  # tag to add if zeromq timeout expires before getting back an answer.
  # If set to "" then no tag will be added.
  config :add_tag_on_timeout, :validate => :string, :default => "zeromqtimeout"

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
    connect
  end #def register

  private
  def close
    @logger.debug("0mq: closing socket.")
    @poller.deregister(@zsocket, ZMQ::POLLIN)
    @zsocket.close
  end #def close

  private
  def connect
    @logger.debug("0mq: connecting socket")
    @zsocket = context.socket(ZMQ::REQ)
    error_check(@zsocket.setsockopt(ZMQ::LINGER, 0),
                "while setting ZMQ::LINGER == 0)")
    @poller = ZMQ::Poller.new
    @poller.register(@zsocket, ZMQ::POLLIN)

    if @sockopt
      #TODO: should make sure that ZMQ::LINGER and ZMQ::POLLIN are not changed
      setopts(@zsocket, @sockopt)
    end

    setup(@zsocket, @address)
  end #def connect

  private
  def reconnect
    close
    connect
  end #def reconnect

  #send and receive data. message is assumed to be json
  #will return a boolean for success, and a string containing one of several things:
  #  - empty string: response from server
  #  - updated string: response from server
  #  - original message: could not send request or get response from server in time 
  private
  def send_recv(message)
    success = false
    @retries.times do
      @logger.debug("0mq: sending", :request => message)
      rc = @zsocket.send_string(message) 
      if ZMQ::Util.resultcode_ok?(rc)
        success = true
        break
      else
        @logger.debug("0mq: error sending message (zmq_errno = #{ZMQ::Util.errno}, zmq_error_string = '#{ZMQ::Util.error_string}'")
        reconnect
      end #if resultcode
    end #retries.times

    #if we did not succeed log it and fail here.
    if not success
      @logger.warn("0mq: error sending message (zmq_errno = #{ZMQ::Util.errno}, zmq_error_string = '#{ZMQ::Util.error_string}'")
      return success, message 
    end

    #now get reply
    reply = ''
    success = false
    @retries.times do 
      @logger.debug("0mq: polling for reply for #{@timeout}ms.")
      #poll the socket. If > 0, something to read. If < 0, error. If zero, loop
      num_readable = @poller.poll(@timeout)
      if num_readable > 0
        #something to read, do it.
        rc = @zsocket.recv_string(reply)
        @logger.debug("0mq: message received, checking error")
        error_check(rc, "in recv_string")
        success = true
        break
      elsif num_readable < 0
        #error, reconnect
        close
        connect
      end
    end # @retries.times
     
    #if we maxed out on number of retries, then set reply to message so that
    #the event isn't cancelled. we want to carry on if the server is down.
    if not success 
      @logger.warn("0mq: did not receive reply (zmq_errno = #{ZMQ::Util.errno}, zmq_error_string = '#{ZMQ::Util.error_string}'")
      return success, message 
    end

    return success, reply
  end #def send_recv

  public
  def filter(event)
    return unless filter?(event)

    begin
      if @field
      	success, reply = send_recv(event[@field])
      else
        success, reply = send_recv(event.to_json)
      end
      # If we receive an empty reply, this is an indication that the filter
      # wishes to cancel this event.
      if reply.empty?
        @logger.debug("0mq: recieved empty reply, cancelling event.")
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
      #if message send/recv was not successful add the timeout
      if not success
        (event["tags"] ||= []) << @add_tag_on_timeout
      end
    rescue => e
      @logger.warn("0mq filter exception", :address => @address, :exception => e, :backtrace => e.backtrace)
    end
  end # def filter

  private
  def server?
    @mode == "server"
  end # def server?

end # class LogStash::Filters::ZeroMQ
