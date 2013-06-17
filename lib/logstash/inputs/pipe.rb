require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Stream events from a long running command pipe.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
#
class LogStash::Inputs::Pipe < LogStash::Inputs::Base
  config_name "pipe"
  milestone 1

  # Command to run and read events from, one line at a time.
  #
  # Example:
  #
  #    command => "echo hello world"
  config :command, :validate => :string, :required => true

  public
  def register
    LogStash::Util::set_thread_name("input|pipe|#{command}")
    @logger.info("Registering pipe input", :command => @command)
  end # def register

  public
  def run(queue)
    @pipe = IO.popen(command, mode="r")
    hostname = Socket.gethostname

    @pipe.each do |line|
      line = line.chomp
      source = "pipe://#{hostname}/#{command}"
      @logger.debug("Received line", :command => command, :line => line)
      e = to_event(line, source)
      if e
        queue << e
      end
    end
  end # def run
end # class LogStash::Inputs::Pipe
