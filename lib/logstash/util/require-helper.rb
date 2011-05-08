require "logger"
require "logstash/namespace"

module LogStash::Util::Require
  class << self
    attr_accessor :logger

    def require(lib, gemdep, message=nil)
      @logger ||= Logger.new(STDERR)
      begin
        require lib
      rescue LoadError => e
        @logger.error("Failed loading '#{lib}'")
      end
    end # def require
  end # class << self
end # def LogStash::Util::Require
