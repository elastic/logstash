require 'lib/net/socketmux'

module LogStash; module Net
  # The MessageClient class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageClient < MessageSocketMux
  end # class MessageClient
end; end # module LogStash::Net
