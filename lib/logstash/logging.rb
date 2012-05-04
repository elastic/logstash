require "logstash/namespace"
require "cabin"
require "logger"

class LogStash::Logger < Cabin::Channel
  attr_accessor :target

  public
  def initialize(*args)
    super()

    # Set default loglevel to WARN unless $DEBUG is set (run with 'ruby -d')
    @level = $DEBUG ? :debug : :warn
    if ENV["LOGSTASH_DEBUG"]
      self.level = :debug
    end

    #self[:program] = File.basename($0)
    #subscribe(::Logger.new(*args))
    @target = args[0]
    subscribe(@target)

    # Direct metrics elsewhere.
    metrics.channel = Cabin::Channel.new
  end # def initialize

  def setup_log4j(logger="")
    require "java"

    #p = java.util.Properties.new(java.lang.System.getProperties())
    p = java.util.Properties.new
    log4j_level = "WARN"
    case level
      when :debug
        log4j_level = "DEBUG"
      when :info
        log4j_level = "INFO"
      when :warn
        log4j_level = "WARN"
    end # case level
    p.setProperty("log4j.rootLogger", "#{log4j_level},logstash")

    case target
      when STDOUT
        p.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.ConsoleAppender")
        p.setProperty("log4j.appender.logstash.Target", "System.out")
      when STDERR
        p.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.ConsoleAppender")
        p.setProperty("log4j.appender.logstash.Target", "System.err")
      else
        p.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.FileAppender")
        p.setProperty("log4j.appender.logstash.File", target)
    end # case target

    p.setProperty("log4j.appender.logstash.layout",
                  "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.logstash.layout.conversionPattern",
                  "log4j, [%d{yyyy-MM-dd}T%d{HH:mm:ss.SSS}] %5p: %c: %m%n")

    org.apache.log4j.LogManager.resetConfiguration
    org.apache.log4j.PropertyConfigurator.configure(p)
    debug("log4j java properties setup", :log4j_level => log4j_level)
  end
end # class LogStash::Logger
