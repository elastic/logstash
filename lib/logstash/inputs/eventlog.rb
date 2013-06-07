require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Pull events from a Windows Event Log
#
# To collect Events from the System Event Log, use a config like:
#
#     input {
#       eventlog {
#         type  => 'Win32-EventLog'
#         logfile  => 'System'
#       }
#     }
class LogStash::Inputs::EventLog < LogStash::Inputs::Base

  config_name "eventlog"
  plugin_status "beta"

  # Event Log Name
  config :logfile, :validate => :array, :default => [ "Application", "Security", "System" ]

  public
  def initialize(params)
    super
    @format ||= "json_event"
  end # def initialize

  public
  def register

    # wrap specified logfiles in suitable OR statements
    @logfiles = @logfile.join("' OR TargetInstance.LogFile = '")

    @hostname = Socket.gethostname
    @logger.info("Registering input eventlog://#{@hostname}/#{@logfile}")

    if RUBY_PLATFORM == "java"
      require "jruby-win32ole"
    else
      require "win32ole"
    end
  end # def register

  public
  def run(queue)
    @wmi = WIN32OLE.connect("winmgmts://")

    wmi_query = "Select * from __InstanceCreationEvent Where TargetInstance ISA 'Win32_NTLogEvent' And (TargetInstance.LogFile = '#{@logfiles}')"

    begin
      @logger.debug("Tailing Windows Event Log '#{@logfile}'")

      events = @wmi.ExecNotificationQuery(wmi_query)

      while
        notification = events.NextEvent
        event = notification.TargetInstance

        timestamp = DateTime.strptime(event.TimeGenerated, "%Y%m%d%H%M%S").iso8601
        timestamp[19..-1] = DateTime.now.iso8601[19..-1] # Copy over the correct TZ offset

        e = LogStash::Event.new({
            "@source" => "eventlog://#{@hostname}/#{@logfile}",
            "@type" => @type,
            "@timestamp" => timestamp
        })

        %w{Category CategoryString ComputerName EventCode EventIdentifier
            EventType Logfile Message RecordNumber SourceName
            TimeGenerated TimeWritten Type User
        }.each{
            |property| e[property] = event.send property 
        }

        if RUBY_PLATFORM == "java"
          # unwrap jruby-win32ole racob data
          e["InsertionStrings"] = unwrap_racob_variant_array(event.InsertionStrings)
          data = unwrap_racob_variant_array(event.Data)
          # Data is an array of signed shorts, so convert to bytes and pack a string
          e["Data"] = data.map{|byte| (byte > 0) ? byte : 256 + byte}.pack("c*")
        else
          # win32-ole data does not need to be unwrapped
          e["InsertionStrings"] = event.InsertionStrings
          e["Data"] = event.Data
        end

        e.message = event.Message

        queue << e

      end # while

    rescue Exception => ex
      @logger.error("Windows Event Log error: #{ex}\n#{ex.backtrace}")
      sleep 1
      retry
    end # rescue

  end # def run

  private
  def unwrap_racob_variant_array(variants)
    variants ||= []
    variants.map {|v| (v.respond_to? :getValue) ? v.getValue : v}
  end # def unwrap_racob_variant_array

end # class LogStash::Inputs::EventLog

