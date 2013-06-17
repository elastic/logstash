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
  
  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false
  
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
    loop do
      start = Time.now
      @logger.info("Running exec", :command => @command) if @debug
      out = IO.popen(@command)
      # out.read will block until the process finishes.
      @codec.decode(out.read) do |event|
        event["source"] = "exec://#{Socket.gethostname}"
        event["command"] = @command
        queue << event
      end
      
      duration = Time.now - start
      if @debug
        @logger.info("Command completed", :command => @command,
                     :duration => duration)
      end

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
