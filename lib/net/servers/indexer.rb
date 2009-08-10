
require 'rubygems'
require 'lib/net/message'
require 'lib/net/socketmux'
require 'lib/net/messages/indexevent'

module LogStash; module Net; module Servers
  class Indexer < LogStash::Net::MessageSocketMux
    def initialize(addr="0.0.0.0", port=3001)
      # 'super' is not the same as 'super()', and we want super().
      super()
      listen(addr, port)
    end

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new
      response.id = request.id
      response.code = 0
      #puts response.inspect
      return response
    end
  end # Indexer
end; end; end # LogStash::Net::Server
