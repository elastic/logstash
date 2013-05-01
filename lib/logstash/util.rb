require "logstash/namespace"

module LogStash::Util
  PR_SET_NAME = 15

  UNAME = case RbConfig::CONFIG["host_os"]
    when /^linux/; "linux"
    else; RbConfig::CONFIG["host_os"]
  end

  module LibC
    if UNAME == "linux"
      require "ffi"
      extend FFI::Library
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
    
    if UNAME == "linux"
      # prctl PR_SET_NAME allows up to 16 bytes for a process name
      # since MRI 1.9, JRuby, and Rubinius use system threads for this.
      LibC.prctl(PR_SET_NAME, name[0..16], 0, 0, 0)
    end
  end # def set_thread_name
end # module LogStash::Util
