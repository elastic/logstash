# encoding: utf-8
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

  # TODO(sissel): This should switch to use the 'line' codec by default
  # once we switch away from doing 'readline'
  default :codec, "plain"

  # Command to run and read events from, one line at a time.
  #
  # Example:
  #
  #    command => "echo hello world"
  config :command, :validate => :string, :required => true

  # Should the pipe be restarted when it exits. Valid values are:
  # * "always" - restart after every exit of the pipe command
  # * "error" - restart only after an erroneous condition of the pipe command
  # * "never" - never restart the pipe command
  #
  # Example:
  #
  #    restart => "always"
  config :restart, :validate => :string, :default => "always", :validate => [ "always", "error", "never" ]


  # Number of seconds to wait before restarting the pipe
  config :wait_on_restart, :validate => :number, :default => 0

  public
  def register
    @logger.info("Registering pipe input", :command => @command)
    @host = Socket.gethostname
  end # def register

  public
  def run(queue)
    loop do
      begin
        IO.popen(@command, mode="r").each do |line|
          line = line.chomp
          @logger.debug? && @logger.debug("Received line", :command => @command, :line => line)
          @codec.decode(line) do |event|
            event["host"] = @host
            event["command"] = @command
            decorate(event)
            queue << event
          end
        end
        break unless @restart == "always"
      rescue LogStash::ShutdownSignal => e
        break
      rescue Exception => e
        @logger.error("Exception while running command", :command => @command, :e => e, :backtrace => e.backtrace)
        break unless @restart == "error" || @restart == "always"
      end
      # Wait before restarting the pipe.
      sleep(@wait_on_restart)
    end
  end # def run
end # class LogStash::Inputs::Pipe
