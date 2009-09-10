
require "lib/net/message"

module LogStash; module Net; module Messages
  class QuitRequest < RequestMessage
    register
  end # class QuitRequest

  class QuitResponse < ResponseMessage
    register
  end # class QuitResponse
end; end; end # module LogStash::Net::Messages
