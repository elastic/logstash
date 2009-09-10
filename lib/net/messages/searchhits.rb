require "lib/net/message"

module LogStash; module Net; module Messages
  class SearchHitsRequest < RequestMessage
    register

    # Message attributes
    hashbind :query, "/args/query"
    hashbind :log_type, "/args/log_type"
    hashbind :offset, "/args/offset"
    hashbind :limit, "/args/limit"
  end # class SearchHitsRequest

  class SearchHitsResponse < ResponseMessage
    register

    # Message attributes
    hashbind :hits, "/args/hits"
  end # class SearchHitsResponse
end; end; end # module LogStash::Net::Messages
