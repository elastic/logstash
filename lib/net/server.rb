require 'lib/net/socketmux'

module LogStash; module Net
  # The MessageServer class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageServer < MessageSocketMux
  end # class MessageServer
end; end # module LogStash::Net
