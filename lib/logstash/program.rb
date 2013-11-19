# encoding: utf-8

require "logstash/namespace"

module LogStash::Program
  public
  def exit(value)
    if RUBY_ENGINE == "jruby"
      # Kernel::exit() in jruby just tosses an exception? Let's actually exit.
      Java::java.lang.System.exit(value)
    else
      Kernel::exit(value)
    end
  end # def exit
end # module LogStash::Program
