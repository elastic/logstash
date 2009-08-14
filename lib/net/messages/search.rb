require "lib/net/message"

module LogStash; module Net; module Messages
  class SearchRequest < RequestMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["request"] == "Search")
    end

    def initialize
      super
      self.name = "Search"
    end

    # Message attributes
    hashbind :query, "/args/query"
    hashbind :log_type, "/args/log_type"
  end # class SearchRequest

  class SearchResponse < ResponseMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["response"] == "Search")
    end

    def initialize
      super
      self.name = "Search"
    end

    # Message attributes
    hashbind :results, "/args/results"
  end # class SearchResponse
end; end; end # module LogStash::Net::Messages
