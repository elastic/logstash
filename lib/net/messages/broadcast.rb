require "lib/net/message"

module LogStash; module Net; module Messages
  class BroadcastMessage < RequestMessage
    register

    # Message attributes
    hashbind :queue, "/args/queue"

  end # class BroadcastRequest

#  class BroadcastResponse < ResponseMessage
#    register
#
#    # Message attributes
#    hashbind :results, "/args/results"
#    hashbind :finished, "/args/finished"
#  end # class BroadcastResponse
end; end; end # module LogStash::Net::Messages
