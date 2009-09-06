require 'rubygems'
require 'lib/net/socket'
require 'lib/net/messages/ping.rb'
require 'stomp'
require 'uuid'

module LogStash; module Net
  class MessageClient < MessageSocket
    # Nothing, yet.
  end # class MessageClient
end; end # module LogStash::Net
