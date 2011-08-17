require "logstash/inputs/base"
require "logstash/namespace"

# Run command line tools and cature output as an event.
#
# Notes:
#
# * The '@source' of this event will be the command run.
# * The '@message' of this event will be the entire stdout of the command
#   as one event.
#
# TODO(sissel): Implement a 'split' filter so you can split output of this
# and other messages by newline, etc.
class LogStash::Inputs::Exec < LogStash::Inputs::Base

  config_name "exec"
  
  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false
  
  # Command to run. For example, "uptime"
  config :command, :validate => :string, :required => true
  
  # Interval to run the command. Value is in seconds.
  config :interval, :validate => :number, :required => true
  
  public
  def register
    @logger.info(["Registering Exec Input", {:type => @type, :exec => @exec, :period => @period}])
  end # def register

  public
  def run(queue)
    loop do
      start = Time.now
      @logger.info("Running: #{@command}") if @debug
      out = IO.popen(@command)
      # out.read will block until the process finishes.
      e = to_event(out.read, @command)
      queue << e
      duration = Time.now - start
      @logger.info("Command '#{@command}' took #{duration} seconds") if @debug

      # Sleep for the remainder of the interval, or 0 if the duration ran
      # longer than the interval.
      sleeptime = [0, @interval - duration].max
      if sleeptime == 0
        @logger.warn("Execution of '#{@command}' ran longer than the interval."
                     " Took #{duration} seconds, but interval is #{@interval}."
                     " Not sleeping...")
      else
        sleep(sleeptime)
      end
    end # loop
  end # def run
end # class LogStash::Inputs::Exec
