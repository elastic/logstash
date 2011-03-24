require "logstash/namespace"

module LogStash::Util
  def self.set_thread_name(name)
    java.lang.Thread.currentThread.setName(name)
  end # def set_thread_name
end # module LogStash::Util
