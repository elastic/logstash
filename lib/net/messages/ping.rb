
require "lib/net/message"

module LogStash; module Net; module Messages
  class PingRequest < RequestMessage
    register

    def initialize
      super
      self.pingdata = Time.now.to_f
    end

    # Message attributes
    hashbind :pingdata, "/args/pingdata"

  end # class PingRequest

  class PingResponse < ResponseMessage
    register

    # Message attributes
    hashbind :pingdata, "/args/pingdata"
  end # class PingResponse
end; end; end # module LogStash::Net::Messages
