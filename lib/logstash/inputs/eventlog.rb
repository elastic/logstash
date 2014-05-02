# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# This input will pull events from a (http://msdn.microsoft.com/en-us/library/windows/desktop/bb309026%28v=vs.85%29.aspx)[Windows Event Log].
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
  milestone 2

  default :codec, "plain"

  # Event Log Name
  config :logfile, :validate => :array, :default => [ "Application", "Security", "System" ]

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

        timestamp = to_timestamp(event.TimeGenerated)

        e = LogStash::Event.new(
          "host" => @hostname,
          "path" => @logfile,
          "type" => @type,
          "@timestamp" => timestamp
        )

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

        e["message"] = event.Message

        decorate(e)
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

  # the event log timestamp is a utc string in the following format: yyyymmddHHMMSS.xxxxxx±UUU
  # http://technet.microsoft.com/en-us/library/ee198928.aspx
  private
  def to_timestamp(wmi_time)
    result = ""
    # parse the utc date string
    /(?<w_date>\d{8})(?<w_time>\d{6})\.\d{6}(?<w_sign>[\+-])(?<w_diff>\d{3})/ =~ wmi_time
    result = "#{w_date}T#{w_time}#{w_sign}"
    # the offset is represented by the difference, in minutes, 
    # between the local time zone and Greenwich Mean Time (GMT).
    if w_diff.to_i > 0
      # calculate the timezone offset in hours and minutes
      h_offset = w_diff.to_i / 60
      m_offset = w_diff.to_i - (h_offset * 60)
      result.concat("%02d%02d" % [h_offset, m_offset])
    else
      result.concat("0000")
    end
  
    return DateTime.strptime(result, "%Y%m%dT%H%M%S%z").iso8601
  end
end # class LogStash::Inputs::EventLog

