require "logstash/namespace"
require "cabin"
require "logger"

class LogStash::Logger < Cabin::Channel
  public
  def initialize(*args)
    super()

    # Set default loglevel to WARN unless $DEBUG is set (run with 'ruby -d')
    @level = $DEBUG ? :debug : :info
    if ENV["LOGSTASH_DEBUG"]
      self.level = :debug
    end

    #self[:program] = File.basename($0)
    subscribe(::Logger.new(*args))
  end # def initialize
end # class LogStash::Logger
