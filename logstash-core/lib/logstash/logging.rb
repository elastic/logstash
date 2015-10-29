# encoding: utf-8
require "logstash/namespace"
require "cabin"
require "logger"

class LogStash::Logger
  attr_accessor :target

  public
  def initialize(*args)
    super()

    #self[:program] = File.basename($0)
    #subscribe(::Logger.new(*args))
    @target = args[0]
    @channel = Cabin::Channel.get(LogStash)

    # lame hack until cabin's smart enough not to doubley-subscribe something.
    # without this subscription count check, running the test suite
    # causes Cabin to subscribe to STDOUT maaaaaany times.
    subscriptions = @channel.instance_eval { @subscribers.count }
    @channel.subscribe(@target) unless subscriptions > 0

    # Set default loglevel to WARN unless $DEBUG is set (run with 'ruby -d')
    @level = $DEBUG ? :debug : :warn
    if ENV["LOGSTASH_DEBUG"]
      @level = :debug
    end

    # Direct metrics elsewhere.
    @channel.metrics.channel = Cabin::Channel.new
  end # def initialize

  # Delegation
  def level=(value) @channel.level = value; end
  def debug(*args); @channel.debug(*args); end
  def debug?(*args); @channel.debug?(*args); end
  def info(*args); @channel.info(*args); end
  def info?(*args); @channel.info?(*args); end
  def warn(*args); @channel.warn(*args); end
  def warn?(*args); @channel.warn?(*args); end
  def error(*args); @channel.error(*args); end
  def error?(*args); @channel.error?(*args); end
  def fatal(*args); @channel.fatal(*args); end
  def fatal?(*args); @channel.fatal?(*args); end

  def self.setup_log4j(logger)
    require "java"

    properties = java.util.Properties.new
    log4j_level = "WARN"
    case logger.level
      when :debug
        log4j_level = "DEBUG"
      when :info
        log4j_level = "INFO"
      when :warn
        log4j_level = "WARN"
    end # case level
    properties.setProperty("log4j.rootLogger", "#{log4j_level},logstash")

    # TODO(sissel): This is a shitty hack to work around the fact that
    # LogStash::Logger isn't used anymore. We should fix that.
    target = logger.instance_eval { @subscribers }.values.first.instance_eval { @io }
    case target
      when STDOUT
        properties.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.ConsoleAppender")
        properties.setProperty("log4j.appender.logstash.Target", "System.out")
      when STDERR
        properties.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.ConsoleAppender")
        properties.setProperty("log4j.appender.logstash.Target", "System.err")
      when target.is_a?(File)
        properties.setProperty("log4j.appender.logstash",
                      "org.apache.log4j.FileAppender")
        properties.setProperty("log4j.appender.logstash.File", target.path)
      else
        properties.setProperty("log4j.appender.logstash", "org.apache.log4j.varia.NullAppender")
    end # case target

    properties.setProperty("log4j.appender.logstash.layout",
                  "org.apache.log4j.PatternLayout")
    properties.setProperty("log4j.appender.logstash.layout.conversionPattern",
                  "log4j, [%d{yyyy-MM-dd}T%d{HH:mm:ss.SSS}] %5p: %c: %m%n")

    org.apache.log4j.LogManager.resetConfiguration
    org.apache.log4j.PropertyConfigurator.configure(properties)
    logger.debug("log4j java properties setup", :log4j_level => log4j_level)
  end
end # class LogStash::Logger
