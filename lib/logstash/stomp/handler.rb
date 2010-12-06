# Base of Stomp Handler
# it handles connecting and subscribing to the stomp broker which
# is used in both stomp input and output
class LogStash::Stomp
  class Handler < EventMachine::Connection
    include EM::Protocols::Stomp

    def initialize(*args)
      super

      @input = args[0]
      @logger = args[1]
      @url = args[2]
    end # def initialize

    def connection_completed
      @logger.debug("Connected")
      connect :login => @url.user, :passcode => @url.password
    end # def connection_completed

    def unbind
      @logger.error(["Error when connecting to stomp broker", { :url => @url }])
    end # def unbind

    def receive_msg(message)
      @logger.debug(["receiving message", { :msg => message }])
      if message.command == "CONNECTED"
        @logger.debug(["subscribing to", { :path => @url.path }])
        subscribe @url.path
        return
      end
    end # def receive_msg
  end # class Handler
end # class LogStash::Stomp
