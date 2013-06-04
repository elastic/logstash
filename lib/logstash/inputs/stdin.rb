require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read events from standard input.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
class LogStash::Inputs::Stdin < LogStash::Inputs::Base

  config_name "stdin"

  plugin_status "beta"

  public
  def register
    enable_codecs
    @host = Socket.gethostname
  end # def register

  def run(queue) 
    while true
      begin
        @codec.decode($stdin.readline.chomp) do |event|
          event["source"] = "stdin://#{@host}/"
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
    $stdin.close
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
