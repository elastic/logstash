require "logstash/namespace"

module LogStash::Util
  def self.set_thread_name(name)
    # Keep java and ruby thread names in sync.
    java.lang.Thread.currentThread.setName(name)
    Thread.current[:name] = name
  end # def set_thread_name
end # module LogStash::Util
