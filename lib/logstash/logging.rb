require "logstash/namespace"
require "logger"

class LogStash::Logger < Logger
  def initialize(*args)
    super(*args)
    @@formatter ||= LogStash::Logger::Formatter.new
    @formatter = @@formatter
  end
end

class LogStash::Logger::Formatter #< Logger::Formatter
  # [:call, "INFO", Wed Oct 27 01:48:46 -0700 2010, nil, {"hello"=>12345}]e
  def call(level, timestamp, object)
    # TODO(sissel): implement
   end
end

#a =Logger.new(STDOUT)
#a.formatter = LogStash::Logger::Formatter.new
#a.level = Logger::INFO
#a.info({"hello" => 12345})

