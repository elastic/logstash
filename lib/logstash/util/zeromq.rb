require 'ffi-rzmq'
require "logstash/namespace"

module LogStash::Util::ZeroMQ
  CONTEXT = ZMQ::Context.new

  def context
    CONTEXT
  end

  def setup(socket, address)
    if server?
      error_check(socket.bind(address), "binding to #{address}")
    else
      error_check(socket.connect(address), "connecting to #{address}")
    end
    @logger.info("0mq: #{server? ? 'connected' : 'bound'}", :address => address)
  end

  def error_check(rc, doing)
    unless ZMQ::Util.resultcode_ok?(rc)
      @logger.error("ZeroMQ error while #{doing}", { :error_code => rc })
      raise "ZeroMQ Error while #{doing}"
    end
  end # def error_check
end # module LogStash::Util::ZeroMQ
