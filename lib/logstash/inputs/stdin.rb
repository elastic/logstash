require "eventmachine-tail"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::Stdin < LogStash::Inputs::Base

  config_name "stdin"

  public
  def register
    @host = Socket.gethostname
  end # def register

  def run(queue)
    loop do
      event = LogStash::Event.new
      event.message = $stdin.readline.chomp
      event.type = @type
      event.tags = @tags.clone rescue []
      event.source = "stdin://#{@host}/"
      @logger.debug(["Got event", event])
      queue << event
    end # loop
  end # def run
end # class LogStash::Inputs::Stdin
