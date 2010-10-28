require "logstash/namespace"
require "logger"
require "ap"

class LogStash::Logger < Logger
  def initialize(*args)
    super(*args)
    @@formatter ||= LogStash::Logger::Formatter.new
    @formatter = @@formatter
  end
end

class LogStash::Logger::Formatter < Logger::Formatter
  # [:call, "INFO", Wed Oct 27 01:48:46 -0700 2010, nil, {"hello"=>12345}]e
  def call(level, timestamp, progname, object)
    #TODO(sissel): implement
    super(level, timestamp, progname, object.awesome_inspect)
  end
end # class LogStash::Logger::Formatter

#a =Logger.new(STDOUT)
#a.formatter = LogStash::Logger::Formatter.new
#a.level = Logger::INFO
#a.info({"hello" => 12345})

