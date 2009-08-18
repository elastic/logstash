require 'rubygems'
require 'eventmachine'
require 'lib/net/socket'

module LogStash; module Net
  # The MessageServer class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageServer
    def initialize(host, port)
      @host = host
      @port = port
    end

    def run
      EventMachine.run do
        listen(@host, @port)
      end
    end

    def listen(host, port)
      EventMachine::start_server(host, port, MessageSocket) do |m|
        m.handler = self
      end
    end
  end # class MessageServer
end; end # module LogStash::Net
