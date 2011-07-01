require "rubygems"
require "optparse"
$:.unshift "#{File.dirname(__FILE__)}/../lib"
$:.unshift "#{File.dirname(__FILE__)}/../test"
require "logstash/namespace"
require "logstash/loadlibs"

class LogStash::Test
  def check_lib(lib, provider, optional=true, message=nil)
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
  end

  def report_ruby_version
    puts "Running #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} on #{RUBY_PLATFORM}"
  end

  def check_libraries
    results = [
      # main agent
      check_lib("grok", "jls-grok", true, "needed for the grok filter."),
      check_lib("bunny", "bunny", true, "needed for AMQP input and output"),
      check_lib("uuidtools", "uuidtools", true,
                "needed for AMQP input and output"),
      check_lib("ap", "awesome_print", true, "improve debug logging output"),
      check_lib("json", "json", false, "required for logstash to function"),
      check_lib("filewatch/tailglob", "filewatch", false,
                "required for file input"),
      check_lib("jruby-elasticsearch", "jruby-elasticsearch", false,
                "required for elasticsearch output and for logstash web"),
      check_lib("stomp", "stomp", false,
                "required for stomp input and output"),
      check_lib("mongo", "mongo", false, "required for mongo output"),
      check_lib("redis", "redis", false,
                "required for stomp input and output"),
      check_lib("gelf", "gelf", false, "required for gelf (graylog2) output"),

      # logstash web
      check_lib("mizuno", "mizuno", true, "needed for logstash web"),
      check_lib("rack", "rack", true, "needed for logstash web"),
      check_lib("sinatra", "sinatra", true, "needed for logstash web"),
      check_lib("sass", "sass", true, "needed for logstash web"),
      check_lib("haml", "haml", true, "needed for logstash web"),
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
  end

  def run_tests
    require File.join(File.dirname(__FILE__), 
                      *%w{.. .. test logstash_test_runner})
    return Test::Unit::AutoRunner.run
  end # def run_tests

  def run(args)
    @success = true
    @thread = Thread.new do
      report_ruby_version
      # TODO(sissel): Add a way to call out specific things to test, like
      # logstash-web, elasticsearch, mongodb, syslog, etc.
      if !check_libraries
        puts "Library check failed."
        @success = false
      end

      if !run_tests
        puts "Test suite failed."
        @success = false
      end
    end
    return args
  end # def run

  def wait
    @thread.join
    return @success ? 0 : 1
  end # def wait
end # class LogStash::Test
