# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require 'win32/eventlog'
require 'java'
include Win32

java_import 'java.lang.System'

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

  # Event Log Name "Application", "Security", "System"
  config :logfile, :validate => :string, :default => [ "Application" ]

  # Where to write the sincedb database (keeps track of the current
  # position of monitored event logs).
  config :sincedb_path, :validate => :string

  # How often (in seconds) to write a since database with the current position of
  # monitored event logs.
  config :sincedb_write_interval, :validate => :number, :default => 15

  # The delay between reads is due to the nature of the Windows event log.
  # It is not really designed to be tailed in the manner of a Unix syslog,
  # for example, in that not nearly as many events are typically recorded.
  # It's just not designed to be polled that heavily.
  config :frequency, :validate => :number, :default => 5

  # Choose where Logstash starts initially reading files: at the beginning or
  # at the end. The default behavior treats files like live streams and thus
  # starts at the end. If you have old data you want to import, set this
  # to 'beginning'
  #
  # This option only modifies "first contact" situations where a file is new
  # and not seen before. If a file has already been seen before, this option
  # has no effect.
  config :start_position, :validate => [ "beginning", "end"], :default => "end"

  public
  def register

    @hostname = Socket.gethostname
    @logger.info("Registering input eventlog://#{@hostname}/#{@logfile}")
    @eventlog = EventLog.new(@logfile)

    @sincedb = {}
    @sincedb_last_write = 0
    @sincedb_write_pending = false
    @sincedb_writing = false
    @eventlog_item = nil
    @queue = nil

    _sincedb_open
  end # def register

  public
  def run(queue)
    @queue = queue
    begin
      rec_num = 0
      old_total = 0
      flags = EventLog::FORWARDS_READ | EventLog::SEEK_READ

      if(@sincedb[@logfile] != nil && @sincedb[@logfile].to_i > @eventlog.oldest_record_number)
        rec_num = @sincedb[@logfile].to_i
        @logger.debug("run: Starting #{@logfile} at rec #{rec_num.to_s}")
      elsif(@start_position == "end")
        rec_num = @eventlog.read_last_event.record_number
        @logger.debug("run: Starting #{@logfile} at rec #{rec_num.to_s}")
      else
        @logger.debug("run: Start #{@logfile} from the beginning")
        @eventlog.read{ |eventlog_item|
          @eventlog_item = eventlog_item
          send_logstash_event()
          rec_num = @eventlog_item.record_number
        }
      end

      @logger.debug("Tailing Windows Event Log '#{@logfile}'")
      while true
        if old_total != @eventlog.total_records()
          @eventlog.read(flags, rec_num){ |eventlog_item|
            @eventlog_item = eventlog_item
            if( @eventlog_item.record_number > rec_num )
              send_logstash_event()
            end
            old_total = @eventlog.total_records()
            rec_num = @eventlog_item.record_number
          }
        end
        sleep frequency
      end # while
    rescue Exception => ex
      @logger.error("Windows Event Log error: #{ex}\n#{ex.backtrace}")
      sleep 1
      retry
    end # rescue
  end # run

  private
  def send_logstash_event()
    timestamp = @eventlog_item.time_generated

    e = LogStash::Event.new(
      "host" => @hostname,
      "path" => @logfile,
      "type" => @type,
      "@timestamp" => timestamp
    )

    e["Category"] = @eventlog_item.category
    e["ComputerName"] = @eventlog_item.computer
    e["Data"] = @eventlog_item.data == nil ? nil : @eventlog_item.data.force_encoding('iso-8859-1')
    e["Description"] = @eventlog_item.description == nil ? nil : @eventlog_item.description.force_encoding('iso-8859-1')
    e["EventId"] = @eventlog_item.event_id
    e["EventType"] = @eventlog_item.event_type
    e["Logfile"] = @logfile
    e["Message"] = @eventlog_item.string_inserts.map{ |monostring|
      monostring == nil ? nil : monostring.force_encoding('iso-8859-1')
    }
    e["RecordNumber"] = @eventlog_item.record_number
    e["SourceName"] = @eventlog_item.source
    e["TimeGenerated"] = @eventlog_item.time_generated
    e["TimeWritten"] = @eventlog_item.time_written
    e["Type"] = @eventlog_item.event_type
    e["User"] = @eventlog_item.user

    decorate(e)
    @queue << e

    @sincedb[@logfile] = @eventlog_item.record_number
    _sincedb_write

    e = nil
    timestamp = nil
  end # send_logstash_event

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
    db.close
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

    if(@sincedb_writing)
      @logger.warn("_sincedb_write already writing")
      return
    end

    @sincedb_writing = true

    if (!sincedb_force_write)
       now = Time.now.to_i
       delta = now - @sincedb_last_write

       # we will have to flush out the sincedb file after the interval expires.  So, we will try again later.
       if delta < @sincedb_write_interval
         @sincedb_write_pending = true
         @sincedb_writing = false
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
      @sincedb_writing = false
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
    @sincedb_writing = false

    System.gc()
  end # def _sincedb_write

  public
  def teardown
    sincedb_write
  end # def teardown

end # class LogStash::Inputs::EventLog

