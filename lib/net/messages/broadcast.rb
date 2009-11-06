require "mqrpc"

module LogStash; module Net; module Messages
  class BroadcastMessage < MQRPC::Message
    argument :queue
  end # class BroadcastRequest
end; end; end # module LogStash::Net::Messages
