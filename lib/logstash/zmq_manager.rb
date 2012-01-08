require 'ffi-rzmq'
require 'thread'

class LogStash::ZMQManager
  @@sockets = Array.new
  @@mutex = Mutex.new

  def self.get_context
    unless defined? @@context and @@context
      @@mutex.synchronize do
        @@context = ZMQ::Context.new
      end
    end
    @@context
  end

  def self.socket(type)
    socket = get_context.socket type
    @@sockets.push socket
    return socket
  end

  def self.terminate
    @@context.terminate
  end
end
