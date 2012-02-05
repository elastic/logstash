require 'ffi-rzmq'
require 'thread'

# singelton to hold the processwide ZMQ::Context
class LogStash::ZMQManager
  @@sockets = Array.new
  @@mutex = Mutex.new
  @@context = nil
  @@threads = nil

  # It only makes sense to set this before context has been instanciated
  def self.threads=(n_threads)
    unless @@context
      @@threads ||= n_threads
    end
    self.threads
  end

  def self.threads
    @@threads || 1
  end

  def self.get_context()
    unless @@context
      @@mutex.synchronize do
        @@context = ZMQ::Context.new threads
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
