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

  public
  def register
    @logger.info("Registering pipe input", :command => @command)
  end # def register

  public
  def run(queue)
    loop do
      begin
        @pipe = IO.popen(@command, mode="r")
        hostname = Socket.gethostname

        @pipe.each do |line|
          line = line.chomp
          source = "pipe://#{hostname}/#{@command}"
          @logger.debug? && @logger.debug("Received line", :command => @command, :line => line)
          @codec.decode(line) do |event|
            event["host"] = hostname
            event["command"] = @command
            decorate(event)
            queue << event
          end
        end
      rescue LogStash::ShutdownSignal => e
        break
      rescue Exception => e
        @logger.error("Exception while running command", :e => e, :backtrace => e.backtrace)
      end

      # Keep running the command forever.
      sleep(10)
    end
  end # def run
end # class LogStash::Inputs::Pipe
