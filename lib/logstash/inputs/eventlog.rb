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
#         sincedb_path  => 'C:/ProgramData/Logstash/eventlog-System.sincedb'
#       }
#     }
class LogStash::Inputs::EventLog < LogStash::Inputs::Base

  config_name "eventlog"
  milestone 2

  default :codec, "plain"

  # Event Log Name
  config :logfile, :validate => :array, :default => [ "Application", "Security", "System" ]

  # Where to write the sincedb database (keeps track of the current
  # position of monitored event logs).
  config :sincedb_path, :validate => :string

  # How often (in seconds) to write a since database with the current position of
  # monitored event logs.
  config :sincedb_write_interval, :validate => :number, :default => 15

  public
  def register

    # wrap specified logfiles in suitable OR statements
    @logfiles = @logfile.join("' OR TargetInstance.LogFile = '")

    @hostname = Socket.gethostname
    @logger.info("Registering input eventlog://#{@hostname}/#{@logfile}")

    @sincedb = {}
    @sincedb_last_write = 0
    @sincedb_write_pending = false

    if RUBY_PLATFORM == "java"
      require "jruby-win32ole"
    else
      require "win32ole"
    end

    _sincedb_open
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

        if @sincedb[event.Logfile] != nil && event.RecordNumber - 1 > @sincedb[event.Logfile]
          oldwmi_query = "Select * from Win32_NTLogEvent Where LogFile='#{event.Logfile}' And RecordNumber > #{@sincedb[event.Logfile]} And RecordNumber < #{event.RecordNumber}"
          #Know bug event send in reverse order, because no sort in WQL and no reverse_each in RubyWIN32OLE
          @wmi.ExecQuery(oldwmi_query).each{ |oldevent|
            oldtimestamp = to_timestamp(oldevent.TimeGenerated)

            oe = LogStash::Event.new(
              "host" => @hostname,
              "path" => @logfile,
              "type" => @type,
              "@timestamp" => oldtimestamp
            )

            %w{Category CategoryString ComputerName EventCode EventIdentifier
                EventType Logfile Message RecordNumber SourceName
                TimeGenerated TimeWritten Type User
            }.each{
                |property| oe[property] = oldevent.send property 
            }

            if RUBY_PLATFORM == "java"
              # unwrap jruby-win32ole racob data
              oe["InsertionStrings"] = unwrap_racob_variant_array(oldevent.InsertionStrings)
              data = unwrap_racob_variant_array(oldevent.Data)
              # Data is an array of signed shorts, so convert to bytes and pack a string
              oe["Data"] = data.map{|byte| (byte > 0) ? byte : 256 + byte}.pack("c*")
            else
              # win32-ole data does not need to be unwrapped
              oe["InsertionStrings"] = oldevent.InsertionStrings
              oe["Data"] = oldevent.Data
            end

            oe["message"] = oldevent.Message

            decorate(oe)
            queue << oe
          }
        end

        decorate(e)
        queue << e

        @sincedb[event.Logfile] = event.RecordNumber
        _sincedb_write

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

  private
  def sincedb_write(reason=nil)
    @logger.debug("caller requested sincedb write (#{reason})")
    _sincedb_write(true)  # since this is an external request, force the write
  end

  private
  def _sincedb_open
    path = @sincedb_path
    begin
      db = File.open(path)
    rescue
      @logger.debug("_sincedb_open: #{path}: #{$!}")
      return
    end

    @logger.debug("_sincedb_open: reading from #{path}")
    db.each do |line|
      eventlogname, recordnumber = line.split(" ", 2)
      @logger.debug("_sincedb_open: setting #{eventlogname} to #{recordnumber.to_i}")
      @sincedb[eventlogname] = recordnumber.to_i
    end
  end # def _sincedb_open

  private
  def _sincedb_write_if_pending

    #  Check to see if sincedb should be written out since there was a file read after the sincedb flush, 
    #  and during the sincedb_write_interval

    if @sincedb_write_pending
	_sincedb_write
    end
  end

  private
  def _sincedb_write(sincedb_force_write=false)

    # This routine will only write out sincedb if enough time has passed based on @sincedb_write_interval
    # If it hasn't and we were asked to write, then we are pending a write.

    # if we were called with force == true, then we have to write sincedb and bypass a time check 
    # ie. external caller calling the public sincedb_write method

    if (!sincedb_force_write)
       now = Time.now.to_i
       delta = now - @sincedb_last_write

       # we will have to flush out the sincedb file after the interval expires.  So, we will try again later.
       if delta < @sincedb_write_interval
         @sincedb_write_pending = true
         return
       end
    end

    @logger.debug("writing sincedb (delta since last write = #{delta})")

    path = @sincedb_path
    tmp = "#{path}.new"
    begin
      db = File.open(tmp, "w")
    rescue => e
      @logger.warn("_sincedb_write failed: #{tmp}: #{e}")
      return
    end

    @sincedb.each do |eventlogname, recordnumber|
      db.puts([eventlogname, recordnumber].flatten.join(" "))
    end
    db.close

    begin
      File.rename(tmp, path)
    rescue => e
      @logger.warn("_sincedb_write rename/sync failed: #{tmp} -> #{path}: #{e}")
    end

    @sincedb_last_write = now
    @sincedb_write_pending = false

  end # def _sincedb_write

  public
  def teardown
    sincedb_write
  end # def teardown

end # class LogStash::Inputs::EventLog
