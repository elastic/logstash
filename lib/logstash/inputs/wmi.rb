require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Collect data from WMI query
#
# This is useful for collecting performance metrics and other data
# which is accessible via WMI on a Windows host
#
# Example:
#
#     input {
#       wmi {
#         query => "select * from Win32_Process"
#         interval => 10
#       }
#       wmi {
#         query => "select PercentProcessorTime from Win32_PerfFormattedData_PerfOS_Processor where name = '_Total'"
#       }
#     }
class LogStash::Inputs::WMI < LogStash::Inputs::Base

  config_name "wmi"
  plugin_status "experimental"

  # WMI query
  config :query, :validate => :string, :required => true
  # Polling interval
  config :interval, :validate => :number, :default => 10
  
  public
  def register

    @host = Socket.gethostname
    @logger.info("Registering input wmi://#{@host}/#{@query}")

    if RUBY_PLATFORM == "java"
      # make use of the same fix used for the eventlog input
      require "logstash/inputs/eventlog/racob_fix"
      require "jruby-win32ole"
    else
      require "win32ole"
    end
  end # def register

  public
  def run(queue)
    @wmi = WIN32OLE.connect("winmgmts://")
    
    begin
      @logger.debug("Executing WMI query '#{@query}'")
      loop do
        @wmi.ExecQuery(@query).each do |event|
          # create a single event for all properties in the collection
          e = to_event("", "wmi://#{@host}/#{@query}")
          event.Properties_.each do |prop|
            e[prop.name] = prop.value
          end
          queue << e
        end
        sleep @interval
      end # loop
    rescue Exception => ex
      @logger.error("WMI query error: #{ex}\n#{ex.backtrace}")
      sleep @interval
      retry
    end # begin/rescue
  end # def run
end # class LogStash::Inputs::WMI
