require "mqrpc"

module LogStash; module Net; module Messages
  class PingRequest < MQRPC::RequestMessage
    argument :pingdata

    def initialize
      super
      self.pingdata = Time.now.to_f
    end
  end # class PingRequest

  class PingResponse < MQRPC::ResponseMessage
    argument :pingdata
  end # class PingResponse
end; end; end # module LogStash::Net::Messages
