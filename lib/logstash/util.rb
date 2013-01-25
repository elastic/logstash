require "logstash/namespace"
require "ffi" # gem ffi
require "sys/uname" # gem sys-uname

module LogStash::Util
  PR_SET_NAME = 15
  UNAME = Sys::Uname.uname.sysname

  module LibC
    extend FFI::Library
    if UNAME == "Linux"
      ffi_lib 'c'

      # Ok so the 2nd arg isn't really a string... but whaatever
      attach_function :prctl, [:int, :string, :long, :long, :long], :int
    end
  end

  def self.set_thread_name(name)
    if RUBY_ENGINE == "jruby"
      # Keep java and ruby thread names in sync.
      Java::java.lang.Thread.currentThread.setName(name)
    end
    Thread.current[:name] = name
    
    if UNAME == "Linux"
      # prctl PR_SET_NAME allows up to 16 bytes for a process name
      # since MRI 1.9 and JRuby use system threads for this.
      LibC.prctl(PR_SET_NAME, name[0..16], 0, 0, 0)
    end
  end # def set_thread_name
end # module LogStash::Util
