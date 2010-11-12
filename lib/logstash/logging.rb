require "logstash/namespace"
require "logger"

class LogStash::Logger < Logger
  # Try to load awesome_print, if it fails, log it later
  # but otherwise we should continue to operate as normal.
  begin 
    require "ap"
    @@have_awesome_print = true
  rescue LoadError => e
    @@have_awesome_print = false
    @@notify_awesome_print_load_failed = e
  end

  def initialize(*args)
    super(*args)
    @formatter = LogStash::Logger::Formatter.new

    # Set default loglevel to WARN unless $DEBUG is set (run with 'ruby -d')
    self.level = $DEBUG ? Logger::DEBUG: Logger::INFO

    # Conditional support for awesome_print
    if !@@have_awesome_print && @@notify_awesome_print_load_failed
      info [ "Failed: require 'ap' (aka awesome_print); some " \
             "logging features may be disabled", 
             @@notify_awesome_print_load_failed ]
      @@notify_awesome_print_load_failed = nil
    end

    @formatter.progname = self.send(:progname=, File.basename($0))
    info("Using formatter: #{@formatter}")
  end # def initialize

  def level=(level)
    super(level)
    @formatter.level = level
  end # def level=
end # class LogStash::Logger

# Implement a custom Logger::Formatter that uses awesome_inspect on non-strings.
class LogStash::Logger::Formatter < Logger::Formatter
  attr_accessor :level
  attr_accessor :progname

  def call(severity, timestamp, who, object)
    # override progname to be the caller if the log level threshold is DEBUG
    # We only do this if the logger level is DEBUG because inspecting the
    # stack and doing extra string manipulation can have performance impacts
    # under high logging rates.
    if @level == Logger::DEBUG
      # callstack inspection, include our caller
      # turn this: "/usr/lib/ruby/1.8/irb/workspace.rb:52:in `irb_binding'"
      # into this: ["/usr/lib/ruby/1.8/irb/workspace.rb", "52", "irb_binding"]
      #
      # caller[3] is actually who invoked the Logger#<type>
      # This only works if you use the severity methods
      path, line, method = caller[3].split(/(?::in `|:|')/)
      # Trim RUBYLIB path from 'file' if we can
      whence = $:.select { |p| path.start_with?(p) }[0]
      if !whence
        # We get here if the path is not in $:
        file = path
      else
        file = path[whence.length + 1..-1]
      end
      who = "#{file}:#{line}##{method}"
    end

    # Log like normal if we got a string.
    if object.is_a?(String)
      super(severity, timestamp, who, object)
    else
      # If we logged an object, use .awesome_inspect (or just .inspect)
      # to stringify it for higher sanity logging.
      if object.respond_to?(:awesome_inspect)
        super(severity, timestamp, who, object.awesome_inspect)
      else
        super(severity, timestamp, who, object.inspect)
      end
    end
  end # def call
end # class LogStash::Logger::Formatter
