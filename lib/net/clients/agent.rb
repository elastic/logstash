require 'lib/config/agent'
require 'lib/net/client'
require 'lib/net/messages/indexevent'
require 'lib/file/tail/since'
require 'socket'

module LogStash; module Net; module Clients
  class Agent < LogStash::Net::MessageClient
    def initialize(configfile, logger)
      @config = LogStash::Config::AgentConfig.new(configfile)
      super(@config, nil)
      @hostname = Socket.gethostname
      @msgs = []
      @logger = logger
    end # def initialize

    def start_log_watcher
      @config.sources.each do |file, logtype|
        Thread.new do
          @logger.info "Watching #{file} (type #{logtype})"
          File::Tail::Since.new(file).tail do |line|
            index(logtype, line.chomp)
          end
        end
      end
    end # def start_log_watcher

    def index(type, string)
      ier = LogStash::Net::Messages::IndexEventRequest.new
      ier.log_type = type
      ier.log_data = string.strip_upper_ascii
      ier.metadata["source_host"] = @hostname

      @logger.debug "Indexing #{type}: #{string}"
      sendmsg("logstash", ier)
    end # def index

    def IndexEventResponseHandler(msg)
      if msg.code != 0
        @logger.warn "Error indexing line (code=#{msg.code}): #{msg.error}"
      end
    end # def IndexEventResponseHandler

    def run
      start_log_watcher
      super
    end
  end
end; end; end # LogStash::Net::Clients
