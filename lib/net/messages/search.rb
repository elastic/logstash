require "mqrpc"

module LogStash; module Net; module Messages
  class SearchRequest < MQRPC::RequestMessage
    argument :query
    argument :log_type
    argument :offset
    argument :limit
  end # class SearchRequest

  class SearchResponse < MQRPC::ResponseMessage
    argument :results
    argument :indexer_id
    argument :finished
  end # class SearchResponse
end; end; end # module LogStash::Net::Messages
