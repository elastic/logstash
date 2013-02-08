require "logstash/namespace"
require "ffi" # gem ffi

module LogStash::Util
  PR_SET_NAME = 15

  # This can throw an exception, if it does, we're probably not on linux.
  # It certainly throws an exception on Windows; I don't know how
  # to work around it other than this hack.
  begin
    require "sys/uname" # gem sys-uname
    UNAME = Sys::Uname.uname.sysname
  rescue LoadError, FFI::NotFoundError
    UNAME = "unknown"
  end

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
