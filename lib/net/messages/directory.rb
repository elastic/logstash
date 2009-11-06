require "mqrpc"

module LogStash; module Net; module Messages
  class DirectoryRequest < MQRPC::RequestMessage
    # No message attributes
  end # class DirectoryRequest

  class DirectoryResponse < MQRPC::ResponseMessage
    argument :indexers
  end # class DirectoryResponse
end; end; end # module LogStash::Net::Messages
