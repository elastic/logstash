require 'ffi-rzmq'
require "logstash/namespace"

module LogStash::Util::ZeroMQ
  CONTEXT = ZMQ::Context.new

  def context
    CONTEXT
  end

  def setup_socket(socket, address)
    if server?
      error_check(socket.bind(address), "binding to #{address}")
    else
      error_check(socket.connect(address), "connecting to #{address}")
    end
    @logger.info("0mq: #{server? ? 'connected' : 'bound'}", :address => address)
  end

  def setup
    @zsocket = context.socket(@zmq_const)

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    # TODO (lusis)
    # wireup sockopt hash
    if @sockopt
      @sockopt.each do |opt,value|
        sockopt = opt.split('::')[1]
        option = ZMQ.const_defined?(sockopt) ? ZMQ.const_get(sockopt) : ZMQ.const_missing(sockopt)
        error_check(@zsocket.setsockopt(option, value),
                "while setting #{opt} == #{value})")
      end
    end
    
    @address.each do |addr|
      setup_socket(@zsocket, addr)
    end
  end

  def error_check(rc, doing)
    unless ZMQ::Util.resultcode_ok?(rc)
      @logger.error("ZeroMQ error while #{doing}", { :error_code => rc })
      raise "ZeroMQ Error while #{doing}"
    end
  end # def error_check

  def reload
    error_check(@zsocket.close, "while closing socket")
    setup
  end

end # module LogStash::Util::ZeroMQ
