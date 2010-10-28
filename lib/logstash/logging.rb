require "logstash/namespace"
require "logger"
require "ap"

class LogStash::Logger < Logger
  @@formatter = LogStash::Logger::Formatter.new
  def initialize(*args)
    super(*args)
    @formatter = @@formatter
  end
end

# Implement a custom Logger::Formatter that uses awesome_inspect on non-strings.
class LogStash::Logger::Formatter < Logger::Formatter
  def call(level, timestamp, progname, object)
    if object.is_a?(String)
      super(level, timestamp, progname, object)
    else
      super(level, timestamp, progname, object.awesome_inspect)
    end
  end
end # class LogStash::Logger::Formatter

#a =Logger.new(STDOUT)
#a.formatter = LogStash::Logger::Formatter.new
#a.level = Logger::INFO
#a.info({"hello" => 12345})

