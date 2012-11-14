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

  # Set the encoding of the file.
  config :encoding, :validate => :string

  public
  def register
    @host = Socket.gethostname

    if @encoding
      $stdin.set_encoding(@encoding)
    end
  end # def register

  def run(queue)
    loop do
       begin
         line = $stdin.readline.encode("UTF-8").chomp
         e = to_event(line, "stdin://#{@host}/")
       rescue EOFError => ex
         break
       end
      if e
        queue << e
      end
    end # loop
  end # def run

  public
  def teardown
    $stdin.close
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
