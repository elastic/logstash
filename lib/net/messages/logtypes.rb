require "lib/net/message"

module LogStash; module Net; module Messages
  class SearchRequest < RequestMessage
    register

    # Message attributes
    hashbind :query, "/args/query"
    hashbind :log_type, "/args/log_type"
    hashbind :offset, "/args/offset"
    hashbind :limit, "/args/limit"

  end # class SearchRequest

  class SearchResponse < ResponseMessage
    register

    # Message attributes
    hashbind :results, "/args/results"
    hashbind :finished, "/args/finished"
  end # class SearchResponse
end; end; end # module LogStash::Net::Messages
