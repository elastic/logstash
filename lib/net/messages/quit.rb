require "mqrpc"

module LogStash; module Net; module Messages
  class QuitRequest < MQRPC::RequestMessage
    # No attributes
  end # class QuitRequest

  class QuitResponse < MQRPC::ResponseMessage
    # No attributes
  end # class QuitResponse
end; end; end # module LogStash::Net::Messages
