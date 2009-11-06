require "mqrpc"

module LogStash; module Net; module Messages
  class LogTypesRequest < MQRPC::RequestMessage
    # No message attributes
  end # class LogTypesRequest

  class LogTypesResponse < MQRPC::ResponseMessage
    argument :log_type
    argument :types
  end # class LogTypesResponse
end; end; end # module LogStash::Net::Messages
