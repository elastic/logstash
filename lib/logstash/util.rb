require "logstash/namespace"

module LogStash::Util
  def self.set_thread_name(name)
    if RUBY_ENGINE == "jruby"
      # Keep java and ruby thread names in sync.
      Java::java.lang.Thread.currentThread.setName(name)
    end
    Thread.current[:name] = name
  end # def set_thread_name
end # module LogStash::Util
