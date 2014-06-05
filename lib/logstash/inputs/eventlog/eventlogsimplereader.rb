require_relative 'constants'
require_relative 'structs'
require_relative 'functions'
require "win32/registry"
require 'java'

# The EventLog class encapsulates an Event Log source and provides methods
# for interacting with that source.
class EventLogSimpleReader
  include Windows::Constants
  include Windows::Structs
  include Windows::Functions
  extend Windows::Functions

  # The EventLogSimpleReader::Error is raised in cases where interaction with the
  # event log should happen to fail for any reason.
  class Error < StandardError; end

  # The log is read in chronological order, i.e. oldest to newest.
  FORWARDS_READ = EVENTLOG_FORWARDS_READ

  # The log is read in reverse chronological order, i.e. newest to oldest.
  BACKWARDS_READ = EVENTLOG_BACKWARDS_READ

  # Begin reading from a specific record.
  SEEK_READ = EVENTLOG_SEEK_READ

  # Read the records sequentially. If this is the first read operation, the
  # EVENTLOG_FORWARDS_READ or EVENTLOG_BACKWARDS_READ flags determines
  # which record is read first.
  SEQUENTIAL_READ = EVENTLOG_SEQUENTIAL_READ

  # Event types

  # Information event, an event that describes the successful operation
  # of an application, driver or service.
  SUCCESS = EVENTLOG_SUCCESS

  # Error event, an event that indicates a significant problem such as
  # loss of data or functionality.
  ERROR_TYPE = EVENTLOG_ERROR_TYPE

  # Warning event, an event that is not necessarily significant but may
  # indicate a possible future problem.
  WARN_TYPE = EVENTLOG_WARNING_TYPE

  # Information event, an event that describes the successful operation
  # of an application, driver or service.
  INFO_TYPE = EVENTLOG_INFORMATION_TYPE

  # Success audit event, an event that records an audited security attempt
  # that is successful.
  AUDIT_SUCCESS = EVENTLOG_AUDIT_SUCCESS

  # Failure audit event, an event that records an audited security attempt
  # that fails.
  AUDIT_FAILURE = EVENTLOG_AUDIT_FAILURE

  EVENTLOGFIXDATALENGTH = 56

  # The EventLogStruct encapsulates a single event log record.
  EventLogStruct = Struct.new('EventLogStruct', :record_number,
    :time_generated, :time_written, :event_id, :event_type, :category,
    :source, :computer, :user, :string_inserts, :description, :data
  )

  # The name of the event log source.  This will typically be
  # 'Application', 'System' or 'Security', but could also refer to
  # a custom event log source.
  #
  attr_reader :source

  # Opens a handle to the new EventLog +source+ on the local
  # machine.  Typically, your source will be
  # 'Application, 'Security' or 'System', although you can specify a
  # custom log file as well.
  #
  # If a custom, registered log file name cannot be found, the event
  # logging service opens the 'Application' log file.  This is the
  # behavior of the underlying Windows function, not my own doing.
  #
  def initialize(source = 'Application')
    @source = source || 'Application' # In case of explicit nil

    # Avoid potential segfaults from win32-api
    raise TypeError unless @source.is_a?(String)

    function = 'OpenEventLog'
    @handle = OpenEventLog(nil, @source)

    if @handle == 0
      raise SystemCallError.new(function, FFI.errno)
    end

    # Ensure the handle is closed at the end of a block
    if block_given?
      begin
        yield self
      ensure
        close
      end
    end
  end

  # Class method aliases
  class << self
    alias :open :new
  end

  # Closes the EventLog handle. The handle is automatically closed for you
  # if you use the block form of EventLog.new.
  #
  def close
    CloseEventLog(@handle)
  end

  # Indicates whether or not the event log is full.
  #
  def full?
    ptr = FFI::MemoryPointer.new(:ulong, 1)
    needed = FFI::MemoryPointer.new(:ulong)

    unless GetEventLogInformation(@handle, 0, ptr, ptr.size, needed)
      raise SystemCallError.new('GetEventLogInformation', FFI.errno)
    end

    valreturn = ptr.read_ulong != 0
    needed.free
    needed = nil
    ptr.free
    ptr = nil
    return valreturn
  end

  # Returns the absolute record number of the oldest record.  Note that
  # this is not guaranteed to be 1 because event log records can be
  # overwritten.
  #
  def oldest_record_number
    rec = FFI::MemoryPointer.new(:ulong)

    unless GetOldestEventLogRecord(@handle, rec)
      raise SystemCallError.new('GetOldestEventLogRecord', FFI.errno)
    end

    valreturn = rec.read_ulong
    rec.free
    rec = nil
    return valreturn
  end

  # Returns the total number of records for the given event log.
  #
  def total_records
    total = FFI::MemoryPointer.new(:ulong)

    unless GetNumberOfEventLogRecords(@handle, total)
      raise SystemCallError.new('GetNumberOfEventLogRecords', FFI.errno)
    end

    valreturn = total.read_ulong
    total.free
    total = nil
    return valreturn
  end

  # Iterates over each record in the event log, yielding a EventLogStruct
  # for each record.  The offset value is only used when used in
  # conjunction with the EventLogSimpleReader::SEEK_READ flag.  Otherwise, it is
  # ignored.  If no flags are specified, then the default flags are:
  #
  # EventLogSimpleReader::SEQUENTIAL_READ | EventLogSimpleReader::FORWARDS_READ
  #
  # Note that, if you're performing a SEEK_READ, then the offset must
  # refer to a record number that actually exists.  The default of 0
  # may or may not work for your particular event log.
  #
  # The EventLogStruct struct contains the following members:
  #
  # * record_number  # Fixnum
  # * time_generated # Time
  # * time_written   # Time
  # * event_id       # Fixnum
  # * event_type     # String
  # * category       # String
  # * source         # String
  # * computer       # String
  # * user           # String or nil
  # * description    # String or nil
  # * string_inserts # An array of Strings or nil
  # * data           # binary data or nil
  #
  # If no block is given the method returns an array of EventLogStruct's.
  #
  def read(flags = nil, offset = 0)
    buf    = FFI::MemoryPointer.new(:char, BUFFER_SIZE)
    bufKeeper = buf
    read   = FFI::MemoryPointer.new(:ulong)
    needed = FFI::MemoryPointer.new(:ulong)
    array  = []

    unless flags
      flags = FORWARDS_READ | SEQUENTIAL_READ
    end

    while ReadEventLog(@handle, flags, offset, buf, buf.size, read, needed) ||
      FFI.errno == ERROR_INSUFFICIENT_BUFFER

      if FFI.errno == ERROR_INSUFFICIENT_BUFFER
        buf.free
        bufKeeper = nil
        buf = nil
        buf = FFI::MemoryPointer.new(:char, needed.read_ulong)
        bufKeeper = buf
        unless ReadEventLog(@handle, flags, offset, buf, buf.size, read, needed)
          raise SystemCallError.new('ReadEventLog', FFI.errno)
        end
      end

      dwread = read.read_ulong

      while dwread > 0
        struct = EventLogStruct.new
        record = EVENTLOGRECORD.new(buf)

        variableData = buf.read_bytes(buf.size)[EVENTLOGFIXDATALENGTH..-1]

        struct.source         = variableData[/^[^\0]*/]
        struct.computer       = variableData[struct.source.length + 1..-1][/^[^\0]*/]
        struct.record_number  = record[:RecordNumber]
        struct.time_generated = Time.at(record[:TimeGenerated])
        struct.time_written   = Time.at(record[:TimeWritten])
        struct.event_id       = record[:EventID] & 0x0000FFFF
        struct.event_type     = get_event_type(record[:EventType])
        struct.user           = get_user(record)
        struct.category       = record[:EventCategory]
        struct.string_inserts, struct.description = get_description(variableData, record, struct.source)
        struct.data           = record[:DataLength] <= 0 ? nil : (variableData[record[:DataOffset] - EVENTLOGFIXDATALENGTH, record[:DataLength]])
        struct.freeze # This is read-only information

        if block_given?
          yield struct
        else
          array.push(struct)
        end

        if flags & EVENTLOG_BACKWARDS_READ > 0
          offset = record[:RecordNumber] - 1
        else
          offset = record[:RecordNumber] + 1
        end

        length = record[:Length]

        dwread -= length
        buf += length
      end

      buf = bufKeeper
      buf.clear
    end

    needed.free
    needed = nil
    read.free
    read = nil
    bufKeeper = nil
    buf.free
    buf = nil
    return block_given? ? nil : array
  end

  # This class method is nearly identical to the EventLogSimpleReader#read instance
  # method, except that it takes a +source+ as the first two
  # arguments.
  #
  def self.read(source='Application', flags=nil, offset=0)
    self.new(source){ |log|
      if block_given?
        log.read(flags, offset){ |els| yield els }
      else
        return log.read(flags, offset)
      end
    }
  end

  # A method that reads the last event log record.
  #
  def read_last_event()
    buf    = FFI::MemoryPointer.new(:char, BUFFER_SIZE)
    read   = FFI::MemoryPointer.new(:ulong)
    needed = FFI::MemoryPointer.new(:ulong)

    flags = EVENTLOG_BACKWARDS_READ | EVENTLOG_SEQUENTIAL_READ

    unless ReadEventLog(@handle, flags, 0, buf, buf.size, read, needed)
      if FFI.errno == ERROR_INSUFFICIENT_BUFFER
        buf.free
        buf = nil
        buf = FFI::MemoryPointer.new(:char, needed.read_ulong)
        unless ReadEventLog(@handle, flags, 0, buf, buf.size, read, needed)
          raise SystemCallError.new('ReadEventLog', FFI.errno)
        end
      else
        raise SystemCallError.new('ReadEventLog', FFI.errno)
      end
    end

    struct = EventLogStruct.new
    record = EVENTLOGRECORD.new(buf)

    variableData = buf.read_bytes(buf.size)[EVENTLOGFIXDATALENGTH..-1]

    struct.source         = variableData[/^[^\0]*/]
    struct.computer       = variableData[struct.source.length + 1..-1][/^[^\0]*/]
    struct.record_number  = record[:RecordNumber]
    struct.time_generated = Time.at(record[:TimeGenerated])
    struct.time_written   = Time.at(record[:TimeWritten])
    struct.event_id       = record[:EventID] & 0x0000FFFF
    struct.event_type     = get_event_type(record[:EventType])
    struct.user           = get_user(record)
    struct.category       = record[:EventCategory]
    struct.string_inserts, struct.description = get_description(variableData, record, struct.source)
    struct.data           = record[:DataLength] <= 0 ? nil : (variableData[record[:DataOffset] - EVENTLOGFIXDATALENGTH, record[:DataLength]])

    struct.freeze # This is read-only information

    needed.free
    needed = nil
    read.free
    read = nil
    buf.free
    buf = nil

    return struct
  end

  # Private method that retrieves the user name based on data in the
  # EVENTLOGRECORD buffer.
  #
  def get_user(rec)
    return nil if rec[:UserSidLength] <= 0

    name   = FFI::MemoryPointer.new(:char, MAX_SIZE)
    domain = FFI::MemoryPointer.new(:char, MAX_SIZE)
    snu    = FFI::MemoryPointer.new(:int)

    name_size   = FFI::MemoryPointer.new(:ulong)
    domain_size = FFI::MemoryPointer.new(:ulong)

    name_size.write_ulong(name.size)
    domain_size.write_ulong(domain.size)

    offset = rec[:UserSidOffset]

    val = LookupAccountSid(
      nil,
      rec.pointer + offset,
      name,
      name_size,
      domain,
      domain_size,
      snu
    )

    # Return nil if the lookup failed
    namereturn = val ? name.read_string : nil

    domain_size.free
    domain_size = nil
    name_size.free
    name_size = nil

    snu.free
    snu = nil
    domain.free
    domain = nil
    name.free
    name = nil

    return namereturn
  end

  # Private method that converts a numeric event type into a human
  # readable string.
  #
  def get_event_type(event)
    case event
      when EVENTLOG_ERROR_TYPE
        return 'error'
      when EVENTLOG_WARNING_TYPE
        return 'warning'
      when EVENTLOG_INFORMATION_TYPE, EVENTLOG_SUCCESS
        return 'information'
      when EVENTLOG_AUDIT_SUCCESS
        return return 'audit_success'
      when EVENTLOG_AUDIT_FAILURE
        return 'audit_failure'
      else
        return nil
    end
  end

  # Private method that gets the string inserts (Array) and the full
  # event description (String) based on data from the EVENTLOGRECORD
  # buffer.
  #
  def get_description(variableData, record, event_source)
    str     = record[:DataLength] > 0 ? variableData[record[:StringOffset] - EVENTLOGFIXDATALENGTH .. record[:DataOffset] - EVENTLOGFIXDATALENGTH - 1] : variableData[record[:StringOffset] - EVENTLOGFIXDATALENGTH .. -5]
    num     = record[:NumStrings]
    key     = BASE_KEY + "#{@source}\\#{event_source}"
    buf     = FFI::MemoryPointer.new(:char, 8192)
    va_list = va_list0 = (num == 0) ? [] : str.unpack('Z*' * num)

    begin
      old_wow_val = FFI::MemoryPointer.new(:int)
      Wow64DisableWow64FsRedirection(old_wow_val)

      param_exe = nil
      message_exe = nil

      hkey = Win32::Registry::HKEY_LOCAL_MACHINE.open(key) rescue nil
      if hkey != nil
        guid = hkey["providerGuid"] rescue nil
        if guid != nil
          key2  = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WINEVT\\Publishers\\#{guid}"
          param_file = Win32::Registry::HKEY_LOCAL_MACHINE.open(key2)["ParameterMessageFile"] rescue nil
          message_file = Win32::Registry::HKEY_LOCAL_MACHINE.open(key2)["MessageFileName"] rescue nil

          param_exe = param_file.nil? ? nil : Win32::Registry.expand_environ(param_file)
          message_exe = message_file.nil? ? nil : Win32::Registry.expand_environ(message_file)
        else
          param_file = hkey["ParameterMessageFile"] rescue nil
          message_file = hkey["EventMessageFile"] rescue nil

          param_exe = param_file.nil? ? nil : Win32::Registry.expand_environ(param_file)
          message_exe = message_file.nil? ? nil : Win32::Registry.expand_environ(message_file)
        end
      else
        wevent_source = (event_source + 0.chr).encode('UTF-16LE')

        begin
          pubMetadata = EvtOpenPublisherMetadata(0, wevent_source, nil, 1024, 0)

          if pubMetadata > 0
            buf2 = FFI::MemoryPointer.new(:char, 8192)
            val  = FFI::MemoryPointer.new(:ulong)

            bool = EvtGetPublisherMetadataProperty(
              pubMetadata,
              2, # EvtPublisherMetadataParameterFilePath
              0,
              buf2.size,
              buf2,
              val
            )

            unless bool
              raise SystemCallError.new('EvtGetPublisherMetadataProperty', FFI.errno)
            end

            param_file = buf2.read_string[16..-1]
            param_exe = param_file.nil? ? nil : Win32::Registry.expand_environ(param_file)
            buf2.clear
            val.clear

            bool = EvtGetPublisherMetadataProperty(
              pubMetadata,
              3, # EvtPublisherMetadataMessageFilePath
              0,
              buf2.size,
              buf2,
              val
            )

            unless bool
              raise SystemCallError.new('EvtGetPublisherMetadataProperty', FFI.errno)
            end

            message_file = buf2.read_string[16..-1]
            message_exe = message_file.nil? ? nil : Win32::Registry.expand_environ(message_file)

            val.free
            val = nil
            buf2.free
            buf2 = nil
          end
        ensure
          EvtClose(pubMetadata) if pubMetadata
        end
      end

      if param_exe != nil
        buf.clear
        va_list = va_list0.map{ |v|
          va = v

          v.scan(/%%(\d+)/).uniq.each{ |x|
            param_exe.split(';').each{ |lfile|
              if lfile.to_s.strip.length == 0
                next
              end
              #To fix "string contains null byte" on some registry entry (corrupted?)
              lfile.gsub!(/\0/, '')
              begin
                hmodule  = LoadLibraryEx(
                  lfile,
                  0,
                  DONT_RESOLVE_DLL_REFERENCES | LOAD_LIBRARY_AS_DATAFILE
                )

                if hmodule != 0
                  buf.clear
                  res = FormatMessage(
                    FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_ARGUMENT_ARRAY,
                    hmodule,
                    x.first.to_i,
                    0,
                    buf,
                    buf.size,
                    v
                  )

                  if res == 0
                    event_id = 0xB0000000 | x.first.to_i
                    buf.clear
                    res = FormatMessage(
                      FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_IGNORE_INSERTS,
                      hmodule,
                      event_id,
                      0,
                      buf,
                      buf.size,
                      nil
                    )
                  else
                    next
                  end
                  break if buf.read_string.gsub(/\n+/, '') != ""
                end
              ensure
                FreeLibrary(hmodule) if hmodule && hmodule != 0
              end
            }

            va = va.gsub("%%#{x.first}", buf.read_string.gsub(/\n+/, ''))
          }

          va
        }
      end

      if message_exe != nil
        buf.clear

        # Try to retrieve message *without* expanding the inserts yet
        message_exe.split(';').each{ |lfile|
          if lfile.to_s.strip.length == 0
            next
          end
          #To fix "string contains null byte" on some registry entry (corrupted?)
          lfile.gsub!(/\0/, '')
          #puts "message_exe#" + record[:RecordNumber].to_s + "lfile:" + lfile
          begin
            hmodule = LoadLibraryEx(
              lfile,
              0,
              DONT_RESOLVE_DLL_REFERENCES | LOAD_LIBRARY_AS_DATAFILE
            )

            event_id = record[:EventID]

            if hmodule != 0
              buf.clear
              res = FormatMessage(
                FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_IGNORE_INSERTS,
                hmodule,
                event_id,
                0,
                buf,
                buf.size,
                nil
              )

              if res == 0
                event_id = 0xB0000000 | event_id
                buf.clear
                res = FormatMessage(
                  FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_IGNORE_INSERTS,
                  hmodule,
                  event_id,
                  0,
                  buf,
                  buf.size,
                  nil
                )
              end
              #puts "message_exe#" + record[:RecordNumber].to_s + "buf:" + buf.read_string
              break if buf.read_string != "" # All messages read
            end
          ensure
            FreeLibrary(hmodule) if hmodule && hmodule != 0
          end
        }

        # Determine higest %n insert number
        # Remove %% to fix: The %1 '%2' preference item in the '%3' Group Policy Object did not apply because it failed with error code '%4'%%100790273
        max_insert = [num, buf.read_string.gsub(/%%/, '').scan(/%(\d+)/).map{ |x| x[0].to_i }.max].compact.max
        #puts "message_exe#" + record[:RecordNumber].to_s + "max_insert:" + max_insert.to_s

        # Insert dummy strings not provided by caller
        ((num+1)..(max_insert)).each{ |x| va_list.push("%#{x}") }

        strptrs = []
        if num == 0
          va_list_ptr = nil
        else
          va_list.each{ |x| strptrs << FFI::MemoryPointer.from_string(x) }
          strptrs << nil

          va_list_ptr = FFI::MemoryPointer.new(FFI::Platform::ADDRESS_SIZE/8, strptrs.size)

          strptrs.each_with_index{ |p, i|
            va_list_ptr[i].put_pointer(0, p)
            #unless p.nil?
            #  puts "message_exe2#" + record[:RecordNumber].to_s + "va_list_ptr:" + i.to_s + "/" + p.read_string
            #end
          }
        end

        message_exe.split(';').each{ |lfile|
          if lfile.to_s.strip.length == 0
            next
          end
          #To fix "string contains null byte" on some registry entry (corrupted?)
          lfile.gsub!(/\0/, '')
          #puts "message_exe2#" + record[:RecordNumber].to_s + "lfile:" + lfile
          begin
            hmodule = LoadLibraryEx(
              lfile,
              0,
              DONT_RESOLVE_DLL_REFERENCES | LOAD_LIBRARY_AS_DATAFILE
            )

            event_id = record[:EventID]

            if hmodule != 0
              buf.clear
              res = FormatMessage(
                FORMAT_MESSAGE_FROM_HMODULE |
                FORMAT_MESSAGE_ARGUMENT_ARRAY,
                hmodule,
                event_id,
                0,
                buf,
                buf.size,
                va_list_ptr
              )
              #puts "message_exe2#" + record[:RecordNumber].to_s + "res1:" + res.to_s

              if res == 0
                event_id = 0xB0000000 | event_id
                buf.clear
                res = FormatMessage(
                  FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_ARGUMENT_ARRAY,
                  hmodule,
                  event_id,
                  0,
                  buf,
                  buf.size,
                  va_list_ptr
                )
                #puts "message_exe2#" + record[:RecordNumber].to_s + "res2:" + res.to_s
              end
              #puts "message_exe2#" + record[:RecordNumber].to_s + "buf:" + buf.read_string(60)
              break if buf.read_string != "" # All messages read
            end
          ensure
            FreeLibrary(hmodule) if hmodule && hmodule != 0
          end
        }

        if num != 0
          strptrs.each_with_index{ |p, i|
            unless p.nil?
              p.free
            end
          }
          va_list_ptr.free
          va_list_ptr = nil
        end
      end
    ensure
      Wow64RevertWow64FsRedirection(old_wow_val.read_ulong)
      old_wow_val.free
      old_wow_val = nil
    end

    resultstr = buf.read_string
    buf.free
    buf = nil
    return [va_list0, resultstr]
  end
end
