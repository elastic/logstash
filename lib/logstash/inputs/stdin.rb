require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read events from standard input.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
class LogStash::Inputs::Stdin < LogStash::Inputs::Base

  config_name "stdin"

  public
  def register
    @host = Socket.gethostname
  end # def register

  def run(queue)
    loop do
      event = LogStash::Event.new
      begin
        event.message = $stdin.readline.chomp
      rescue EOFError => e
        @logger.info("Got EOF from stdin input. Ending")
        finished
        return
      end
      event.type = @type
      event.tags = @tags.clone rescue []
      event.source = "stdin://#{@host}/"
      @logger.debug(["Got event", event])
      queue << event
    end # loop
  end # def run
end # class LogStash::Inputs::Stdin
