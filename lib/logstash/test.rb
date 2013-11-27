# encoding: utf-8
require "rubygems"
require "optparse"

# TODO(sissel): Are these necessary anymore?
#$:.unshift "#{File.dirname(__FILE__)}/../lib"
#$:.unshift "#{File.dirname(__FILE__)}/../test"

require "logstash/namespace"
require "logstash/loadlibs"
require "logstash/logging"

class LogStash::Test
  public
  def initialize
    log_to(STDERR)

    # This is lib/logstash/test.rb, so go up 2 directories for the plugin path
    if jarred?(__FILE__)
      @plugin_paths = [ File.dirname(File.dirname(__FILE__)) ]
    else
      @plugin_paths = [ File.dirname(File.dirname(File.dirname(__FILE__))) ]
    end 
    @verbose = 0
  end # def initialize

  private
  def jarred?(path)
    return path =~ /^file:/
  end # def jarred?

  public
  def log_to(target)
    @logger = LogStash::Logger.new(target)
  end # def log_to

  def check_lib(lib, provider, is=:optional, message=nil)
    optional = (is == :optional)
    begin
      require lib
      puts "+ Found #{optional ? "optional" : "required"} library '#{lib}'"
      return { :optional => optional, :found => true }
    rescue LoadError => e
      puts "- Missing #{optional ? "optional" : "required"} library '#{lib}'" \
           "- try 'gem install #{provider}'" \
           "#{optional ? " if you want this library" : ""}. #{message}"
      return { :optional => optional, :found => false }
    end
  end # def check_lib

  def report_ruby_version
    puts "Running #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} on #{RUBY_PLATFORM}"
  end # def report_ruby_version

  def check_libraries
    results = [
      # main agent
      check_lib("grok-pure", "jls-grok", :optional, "needed for the grok filter."),
      check_lib("bunny", "bunny", :optional, "needed for AMQP input and output"),
      check_lib("uuidtools", "uuidtools", :required,
                "needed for AMQP input and output"),
      check_lib("ap", "awesome_print", :optional, "improve debug logging output"),
      check_lib("json", "json", :required, "required for logstash to function"),
      check_lib("filewatch/tail", "filewatch", :optional,
                "required for file input"),
      check_lib("jruby-elasticsearch", "jruby-elasticsearch", :optional,
                "required for elasticsearch output and for logstash web"),
      check_lib("stomp", "stomp", :optional,
                "required for stomp input and output"),
      check_lib("mongo", "mongo", :optional, "required for mongo output"),
      check_lib("redis", "redis", :optional,
                "required for stomp input and output"),
      check_lib("gelf", "gelf", :optional, "required for gelf (graylog2) output"),
      check_lib("statsd", "statsd-ruby", :optional, "required for statsd output"),

      # logstash web
      check_lib("ftw", "ftw", :required, "needed for logstash web"),
      check_lib("rack", "rack", :required, "needed for logstash web"),
      check_lib("sinatra", "sinatra", :required, "needed for logstash web"),
      check_lib("sass", "sass", :required, "needed for logstash web"),
      check_lib("haml", "haml", :required, "needed for logstash web"),
    ]

    missing_required = results.count { |r| !r[:optional] and !r[:found] }
    if missing_required == 0
      puts "All required libraries found :)"
    else
      suffix = (missing_required > 1) ? "ies" : "y"
      puts "FATAL: Missing #{missing_required} required librar#{suffix}"
      return false
    end

    return true
  end # def check_libraries

  # Parse options.
  private
  def options(args)
    # strip out the pluginpath argument if it exists and 
    # extend the LOAD_PATH for the ruby runtime
    opts = OptionParser.new

    opts.on("-v", "Increase verbosity") do
      @verbose += 1
    end

    # Step one is to add test flags.
    opts.on("--pluginpath PLUGINPATH", 
            "Load plugins and test from a pluginpath") do |path|
      @plugin_paths << path
    end # --pluginpath PLUGINPATH

    begin
      remainder = opts.parse(args)
    rescue OptionParser::InvalidOption => e
      @logger.info("Invalid option", :exception => e)
      raise e
    end
    return remainder
  end # def options

  public
  def run(args)
    remainder = options(args)

    if @verbose >= 3  # Uber debugging.
      @logger.level = :debug
      $DEBUG = true
    elsif @verbose == 2 # logstash debug logs
      @logger.level = :debug
    elsif @verbose == 1 # logstash info logs
      @logger.level = :info
    else # Default log level
      @logger.level = :warn
    end

    @success = true
    @thread = Thread.new do
      report_ruby_version

      # TODO(sissel): Rewrite this into a proper test?
      #if !check_libraries
        #puts "Library check failed."
        #@success = false
      #end

      @plugin_paths.each do |path|
        load_tests(path)
      end

      require "minitest/spec"
      @status = MiniTest::Unit.new.run(ARGV)
    end # the runner thread
    return remainder
  end # def run

  def wait
    @thread.join
    return @status
  end # def wait

  # Find tests in a given path. Tests must be in the plugin path +
  # "/test/.../test_*.rb"
  def each_test(basepath, &block)
    if jarred?(basepath)
      # No test/logstash/... hierarchy in the jar, not right now anyway.
      glob_path = File.join(basepath, "logstash", "**", "test_*.rb")
    else
      glob_path = File.join(basepath, "test", "**", "test_*.rb")
    end
    @logger.info("Searching for tests", :path => glob_path)
    Dir.glob(glob_path).each do |path|
      block.call(path)
    end
  end # def each_test

  def load_tests(path)
    each_test(path) do |test|
      @logger.info("Loading test", :test => test)
      require test
    end
  end # def load_tests
end # class LogStash::Test
