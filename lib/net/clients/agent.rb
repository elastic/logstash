require 'lib/config/agent'
require 'lib/net/common'
require 'lib/net/messages/indexevent'
require 'lib/file/tail/since'
require 'socket'

module LogStash; module Net; module Clients
  class Agent < MQRPC::Agent
    def initialize(configfile, logger)
      @config = LogStash::Config::AgentConfig.new(configfile)
      MQRPC::logger = logger
      super(@config)
      @hostname = Socket.gethostname
      @msgs = []
      @log_threads = {}
      @logger = logger
    end # def initialize

    def log_watcher
      loop do
        @logger.debug "Starting log_watcher loop"
        @config.sources.each do |file, logtype|
          next if @log_threads.member?(file)

          Dir.glob(file).each do |path|
            next if @log_threads.member?(path)
            next if File.directory?(path)
            @log_threads[path] = Thread.new do
              @logger.info "Watching #{path} (type #{logtype})"
              File::Tail::Since.new(path).tail do |line|
                index(logtype, line.chomp)
              end
              raise "File::Tail::Since croaked for #{file}!"
            end # Thread
          end # Dir.glob
        end # @config.sources.each

        sleep 60  # only check for new logs every minute
      end # loop
    end # def start_log_watcher

    def index(type, string)
      ier = LogStash::Net::Messages::IndexEventRequest.new
      ier.log_type = type
      ier.log_data = string.strip_upper_ascii
      ier.metadata["source_host"] = @hostname

      @logger.debug "Indexing #{type}: #{string}"
      ier.delayable = true
      sendmsg("logstash", ier)
    end # def index

    def IndexEventResponseHandler(msg)
      if msg.code != 0
        @logger.warn "Error indexing line (code=#{msg.code}): #{msg.error}"
      end
    end # def IndexEventResponseHandler

    def run
      Thread.new { log_watcher }
      super
    end
  end
end; end; end # LogStash::Net::Clients
