require 'rubygems'
require 'lib/net/socket'
require 'lib/net/messages/ping.rb'
require 'logger'
require 'stomp'
require 'uuid'

module LogStash; module Net
  class MessageClient < MessageSocket
    def initialize(config, progname)
      logger = Logger.new(STDOUT)
      logger.progname = progname
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      super(config, logger)
    end
    # Nothing, yet.
  end # class MessageClient
end; end # module LogStash::Net
