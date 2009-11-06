require "mqrpc"

module LogStash; module Net; module Messages
  class SearchHitsRequest < MQRPC::RequestMessage
    argument :query
    argument :log_type
    argument :offset
    argument :limit
  end # class SearchHitsRequest

  class SearchHitsResponse < MQRPC::ResponseMessage
    argument :hits
  end # class SearchHitsResponse
end; end; end # module LogStash::Net::Messages
