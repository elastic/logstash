require "lib/net/message"

module LogStash; module Net; module Messages
  class DirectoryRequest < RequestMessage
    register

    # No message attributes
  end # class SearchRequest

  class DirectoryResponse < ResponseMessage
    register

    # Message attributes
    hashbind :indexers, "/args/results"
  end # class SearchResponse
end; end; end # module LogStash::Net::Messages
