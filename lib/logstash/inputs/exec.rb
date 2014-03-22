# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Run command line tools and capture the whole output as an event.
#
# Notes:
#
# * The '@source' of this event will be the command run.
# * The '@message' of this event will be the entire stdout of the command
#   as one event.
#
class LogStash::Inputs::Exec < LogStash::Inputs::Base

  config_name "exec"
  milestone 2

  default :codec, "plain"

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting was never used by this plugin. It will be removed soon."

  # Command to run. For example, "uptime"
  config :command, :validate => :string, :required => true

  # Interval to run the command. Value is in seconds.
  config :interval, :validate => :number, :required => true

  public
  def register
    @logger.info("Registering Exec Input", :type => @type,
                 :command => @command, :interval => @interval)
  end # def register

  public
  def run(queue)
    hostname = Socket.gethostname
    loop do
      start = Time.now
      @logger.info? && @logger.info("Running exec", :command => @command)
      out = IO.popen(@command)
      # out.read will block until the process finishes.
      @codec.decode(out.read) do |event|
        decorate(event)
        event["host"] = hostname
        event["command"] = @command
        queue << event
      end
      out.close

      duration = Time.now - start
      @logger.info? && @logger.info("Command completed", :command => @command,
                                    :duration => duration)

      # Sleep for the remainder of the interval, or 0 if the duration ran
      # longer than the interval.
      sleeptime = [0, @interval - duration].max
      if sleeptime == 0
        @logger.warn("Execution ran longer than the interval. Skipping sleep.",
                     :command => @command, :duration => duration,
                     :interval => @interval)
      else
        sleep(sleeptime)
      end
    end # loop
  end # def run
end # class LogStash::Inputs::Exec
