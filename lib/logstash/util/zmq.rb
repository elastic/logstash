require 'ffi-rzmq'
require "logstash/namespace"

module LogStash::Util::Zmq
  CONTEXT = ZMQ::Context.new

  def context
    CONTEXT
  end

  def setup(socket, address)
    if server?
      error_check(socket.bind(address))
    else
      error_check(socket.connect(address))
    end
    @logger.info("0mq: #{server? ? 'connected' : 'bound'}", :address => address)
  end

  def error_check(rc)
    unless ZMQ::Util.resultcode_ok?(rc)
      @logger.error("ZMQ error: ", { :error_code => rc })
      raise "ZMQ Error"
    end
  end # def error_check
end # module LogStash::Util::Zmq
