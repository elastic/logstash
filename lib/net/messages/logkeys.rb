require "lib/net/message"

module LogStash; module Net; module Messages
  class LogKeysRequest < RequestMessage
    register

    # Message attributes
    hashbind :log_type, "/args/log_type"
  end # class LogKeysRequest

  class LogKeysResponse < ResponseMessage
    register

    # Message attributes
    hashbind :keys, "/args/keys"
  end # class LogKeysResponse
end; end; end # module LogStash::Net::Messages
