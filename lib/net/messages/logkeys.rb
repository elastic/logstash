require "mqrpc"

module LogStash; module Net; module Messages
  class LogKeysRequest < MQRPC::RequestMessage
    argument :log_type
  end # class LogKeysRequest

  class LogKeysResponse < MQRPC::ResponseMessage
    argument :keys
  end # class LogKeysResponse
end; end; end # module LogStash::Net::Messages
