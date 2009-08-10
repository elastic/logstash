
require 'rubygems'
require 'lib/net/message'
require 'lib/net/server'
require 'lib/net/messages/indexevent'

module LogStash; module Net; module Servers
  class Indexer < LogStash::Net::MessageServer
    def initialize(addr="0.0.0.0", port=3001)
      super(addr, port)
    end

    def IndexEventRequestHandler(request)
      puts "IER: #{request.inspect}"
    end
  end # Indexer
end; end; end # LogStash::Net::Server
