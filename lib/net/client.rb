require 'rubygems'
require 'eventmachine'
require 'lib/net/socket'
require 'lib/net/messages/ping.rb'

module LogStash; module Net
  class MessageClient
    attr_reader :connection

    def initialize(host, port)
      @host = host
      @port = port
    end

    def run
      EventMachine.run do
        connect(@host, @port)
      end
    end

    def connect(host, port)
      @connection = EventMachine::connect(host, port, MessageSocket) do |m|
        m.handler = self
      end
    end

  end # class MessageClient
end; end # module LogStash::Net
