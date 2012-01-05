# 
# Add support for capturing signals into JRuby
#
require 'ffi'

module LogStash::Util::Signals
    module LibC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC
      callback :invoke, [ :int ], :void
      attach_function :signal, [ :int, :invoke], :void
    end
end
