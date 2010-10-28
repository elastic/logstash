require "logstash/namespace"
require "logger"
require "ap"

class LogStash::Logger < Logger
  def initialize(*args)
    super(*args)
    @formatter = LogStash::Logger::Formatter.new

    # Set default loglevel to WARN unless $DEBUG is set (run with 'ruby -d')
    self.send(:level=, $DEBUG ? Logger::DEBUG: Logger::WARN)
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

    if object.is_a?(String)
      super(severity, timestamp, who, object)
    else
      super(severity, timestamp, who, object.awesome_inspect)
    end
  end # def call
end # class LogStash::Logger::Formatter
