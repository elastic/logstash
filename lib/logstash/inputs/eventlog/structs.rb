require 'ffi'

module Windows
  module Structs
    extend FFI::Library
    typedef :ulong, :dword
    typedef :ushort, :word

    class EVENTLOGRECORD < FFI::Struct
      layout(
        :Length, :dword,
        :Reserved, :dword,
        :RecordNumber, :dword,
        :TimeGenerated, :dword,
        :TimeWritten, :dword,
        :EventID, :dword,
        :EventType, :word,
        :NumStrings, :word,
        :EventCategory, :word,
        :ReservedFlags, :word,
        :ClosingRecordNumber, :dword,
        :StringOffset, :dword,
        :UserSidLength, :dword,
        :UserSidOffset, :dword,
        :DataLength, :dword,
        :DataOffset, :dword
      )
    end
  end
end
