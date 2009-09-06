require 'rubygems'
require 'lib/net/socket'
require 'socket'
require 'stomp'
require 'uuid'

module LogStash; module Net
  class MessageServer < MessageSocket
    #def run
      #subscribe("logstash")
      #super
    #end
  end # class MessageServer
end; end # module LogStash::Net
