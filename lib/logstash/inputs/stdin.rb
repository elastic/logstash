require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read events from standard input.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
class LogStash::Inputs::Stdin < LogStash::Inputs::Base
  config_name "stdin"
  milestone 3

  public
  def register
    @host = Socket.gethostname
  end # def register

  def run(queue) 
    require "ap"
    while true
      begin
        line = $stdin.readline.chomp
        @codec.decode(line) do |event|
          event["source"] = @host
          event["type"] = @type if @type
          @tags && @tags.each { |t| event.tag(t) }
          queue << event
        end
      rescue EOFError => ex
        # stdin closed, finish
        break
      end
    end # while true
    finished
  end # def run

  public
  def teardown
    @logger.debug("stdin shutting down.")
    $stdin.close rescue nil
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
