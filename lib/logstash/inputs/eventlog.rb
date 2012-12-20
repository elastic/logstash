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
#         name  => 'System'
#       }
#     }
class LogStash::Inputs::EventLog < LogStash::Inputs::Base

  config_name "eventlog"
  plugin_status "beta"

  # Event Log Name
  config :name, :validate => :string, :required => true, :default => "System"

  public
  def initialize(params)
    super
    @format ||= "json_event"
  end # def initialize

  public
  def register
    @hostname = Socket.gethostname
    @logger.info("Registering input eventlog://#{@hostname}/#{@name}")
    require "win32ole" # rubygem 'win32ole' ('jruby-win32ole' on JRuby)
  end # def register

  public
  def run(queue)
    @wmi = WIN32OLE.connect("winmgmts://")
    # When we start up, assume we've already shipped all the events in the log.
    # TODO: Maybe persist this somewhere else so we can catch up on events that
    #       happened while Logstash was not running (like reboots, etc.).
    #       I suppose it would also be valid to just ship all the events at
    #       start-up, but might have thundering-herd problems with that...
    newest_shipped_event = latest_record_number
    next_newest_shipped_event = newest_shipped_event
    begin
      @logger.debug("Tailing Windows Event Log '#{@name}'")
      loop do
        event_index = 0
        latest_events.each do |event|
          break if event.RecordNumber == newest_shipped_event
          timestamp = DateTime.strptime(event.TimeGenerated, "%Y%m%d%H%M%S").iso8601
          timestamp[19..-1] = DateTime.now.iso8601[19..-1] # Copy over the correct TZ offset
          e = LogStash::Event.new({
            "@source" => "eventlog://#{@hostname}/#{@name}",
            "@type" => @type,
            "@timestamp" => timestamp
          })
          %w{Category CategoryString ComputerName EventCode EventIdentifier
            EventType Logfile Message RecordNumber SourceName
            TimeGenerated TimeWritten Type User
          }.each do |property|
            e[property] = event.send property
          end # each event propery
          e["InsertionStrings"] = unwrap_racob_variant_array(event.InsertionStrings)
          data = unwrap_racob_variant_array(event.Data)
          # Data is an array of signed shorts, so convert to bytes and pack a string
          e["Data"] = data.map{|byte| (byte > 0) ? byte : 256 + byte}.pack("c*")
          queue << e
          # Update the newest-record pointer if I'm shipping the newest record in this batch
          next_newest_shipped_event = event.RecordNumber if (event_index += 1) == 1
        end # lastest_events.each
        newest_shipped_event = next_newest_shipped_event
        sleep 10 # Poll for new events every 10 seconds
      end # loop
    rescue Exception => ex
      @logger.error("Windows Event Log error: #{ex}\n#{ex.backtrace}")
      sleep 1
      retry
    end # begin/rescue
  end # def run

  private
  def latest_events
    wmi_query = "select * from Win32_NTLogEvent where Logfile = '#{@name}'"
    events = @wmi.ExecQuery(wmi_query)
  end # def latest_events

  private
  def latest_record_number
    record_number = 0
    latest_events.each{|event| record_number = event.RecordNumber; break}
    record_number
  end # def latest_record_number

  private
  def unwrap_racob_variant_array(variants)
    variants ||= []
    variants.map {|v| (v.respond_to? :getValue) ? v.getValue : v}
  end # def unwrap_racob_variant_array
end # class LogStash::Inputs::EventLog
