require "lib/net/message"

module LogStash; module Net; module Messages
  class LogTypesRequest < RequestMessage
    register

    # No message attributes
  end # class LogTypesRequest

  class LogTypesResponse < ResponseMessage
    register

    # Message attributes
    hashbind :log_type, "/args/log_type"
    hashbind :types, "/args/types"
  end # class LogTypesResponse
end; end; end # module LogStash::Net::Messages
