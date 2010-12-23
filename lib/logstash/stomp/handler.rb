# Base of Stomp Handler
# it handles connecting and subscribing to the stomp broker which
# is used in both stomp input and output
class LogStash::Stomp
  class Handler < EventMachine::Connection
    include EM::Protocols::Stomp

    attr_accessor :should_subscribe
    attr_accessor :ready

    def initialize(*args)
      super

      @input = args[0]
      @logger = args[1]
      @url = args[2]
      @should_subscribe = true
      @ready = false
    end # def initialize

    def connection_completed
      @logger.debug("Connected")
      connect :login => @url.user, :passcode => @url.password
      @ready = true
    end # def connection_completed

    def unbind
      if $EVENTMACHINE_STOPPING
        @logger.debug(["Connection to stomp broker died (probably since we are exiting)",
                      { :url => @url }])
        return
      end
                    
      @logger.error(["Connection to stomp broker died, retrying.", { :url => @url }])
      @ready = false
      EventMachine::Timer.new(1) do
        reconnect(@url.host, @url.port)
      end
    end # def unbind

    def receive_msg(message)
      @logger.debug(["receiving message", { :msg => message }])
      if message.command == "CONNECTED"
        if @should_subscribe
          @logger.debug(["subscribing to", { :path => @url.path }])
          subscribe @url.path
          return
        end
        @ready = true
      end
    end # def receive_msg
  end # class Handler
end # class LogStash::Stomp
