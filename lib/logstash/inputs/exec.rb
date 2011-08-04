require "logstash/inputs/base"
require "logstash/namespace"

# Sample STDOUT from commands (ex. vmstat)
#

class LogStash::Inputs::Exec < LogStash::Inputs::Base

  config_name "exec"
  
  config :type, :validate => :string, :required => true

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false
  
  # Command to run 
  config :exec, :validate => :string, :required => true
  
  # Period to run the command
  config :period, :validate => :number, :required => true
  
  public
  def register
    @logger.info(["Registering Exec Input", {:type => @type, :exec => @exec, :period => @period}])
  end # def register

  public
  def run(queue)
    while(1)
      out = IO.popen(@exec)
      e = to_event(out.read, @exec)
      queue << e
      sleep @period
    end
  end
end
