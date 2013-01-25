require "rubygems"
require "logstash/namespace"
require "logstash/program"
require "logstash/util"
require "logstash/JRUBY-6970"

if ENV["PROFILE_BAD_LOG_CALLS"]
  # Set PROFILE_BAD_LOG_CALLS=1 in your environment if you want
  # to track down logger calls that cause performance problems
  #
  # Related research here:
  #   https://github.com/jordansissel/experiments/tree/master/ruby/logger-string-vs-block
  #
  # Basically, the following is wastes tons of effort creating objects that are
  # never used if the log level hides the log:
  #
  #     logger.debug("something happend", :what => Happened)
  #
  # This is shown to be 4x faster:
  #
  #     logger.debug(...) if logger.debug?
  #
  # I originally intended to use RubyParser and SexpProcessor to
  # process all the logstash ruby code offline, but it was much
  # faster to write this monkeypatch to warn as things are called.
  require "cabin/mixins/logger"
  module Cabin::Mixins::Logger
    LEVELS.keys.each do |level|
      m = "original_#{level}".to_sym
      predicate = "#{level}?".to_sym
      alias_method m, level
      define_method(level) do |*args|
        if !send(predicate)
          warn("Unconditional log call", :location => caller[0])
        end
        send(m, *args)
      end
    end
  end
end

class LogStash::Runner
  include LogStash::Program

  def main(args)
    LogStash::Util::set_thread_name(self.class.name)
    $: << File.join(File.dirname(__FILE__), "..")

    if args.empty?
      $stderr.puts "No arguments given."
      exit(1)
    end

    #if (RUBY_ENGINE rescue nil) != "jruby"
      #$stderr.puts "JRuby is required to use this."
      #exit(1)
    #end

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      $stderr.puts "Options for fixing this: "
      $stderr.puts "  * If doing 'ruby bin/logstash ...' add --1.9 flag to 'ruby'"
      $stderr.puts "  * If doing 'java -jar ... ' add -Djruby.compat.version=RUBY1_9 to java flags"
      return 1
    end

    #require "java"

    @runners = []
    while !args.empty?
      args = run(args)
    end

    status = []
    @runners.each do |r|
      $stderr.puts "Waiting on #{r.wait.inspect}"
      status << r.wait
    end

    # Avoid running test/unit's at_exit crap
    if status.empty?
      exit(0)
    else
      exit(status.first)
    end
  end # def self.main

  def run(args)
    command = args.shift
    commands = {
      "-v" => lambda { emit_version(args) },
      "-V" => lambda { emit_version(args) },
      "--version" => lambda { emit_version(args) },
      "agent" => lambda do
        require "logstash/agent"
        agent = LogStash::Agent.new
        @runners << agent
        return agent.run(args)
      end,
      "web" => lambda do
        require "logstash/web/runner"
        web = LogStash::Web::Runner.new
        @runners << web
        return web.run(args)
      end,
      "test" => lambda do
        $: << File.join(File.dirname(__FILE__), "..", "..", "test")
        require "logstash/test"
        test = LogStash::Test.new
        @runners << test
        return test.run(args)
      end,
      "rspec" => lambda do
        require "rspec/core/runner"
        require "rspec"
        fixedargs = args.collect do |arg|
          # if the arg ends in .rb or has a "/" in it, assume it's a path.
          if arg =~ /\.rb$/ || arg =~ /\//
            # check if it's a file, if not, try inside the jar if we are in it.
            if !File.exists?(arg) && __FILE__ =~ /file:.*\.jar!\//
              # Try inside the jar.
              jar_root = __FILE__.gsub(/!.*/,"!")
              newpath = File.join(jar_root, args.first)

              # Strip leading 'jar:' path (JRUBY_6970)
              newpath.gsub!(/^jar:/, "")
              if File.exists?(newpath)
                # Add the 'spec' dir to the load path so specs can run
                specpath = File.join(jar_root, "spec")
                $: << specpath unless $:.include?(specpath)
                next newpath
              end
            end
          end
          next arg
        end # args.collect

        # Hack up a runner
        runner = Class.new do
          def initialize(args)
            @args = args
          end
          def run
            @thread = Thread.new do
              @result = RSpec::Core::Runner.run(@args)
            end
          end
          def wait
            @thread.join
            return @result
          end
        end

        $: << File.expand_path("#{File.dirname(__FILE__)}/../../spec")
        require "test_utils"
        #p :args => fixedargs
        rspec = runner.new(fixedargs)
        rspec.run
        @runners << rspec
        return []
      end,
      "irb" => lambda do
        require "irb"
        return IRB.start(__FILE__)
      end,
      "pry" => lambda do
        require "pry"
        return binding.pry
      end
    } # commands

    if commands.include?(command)
      args = commands[command].call
    else
      if command.nil?
        $stderr.puts "No command given"
      else
        $stderr.puts "No such command #{command.inspect}"
      end
      $stderr.puts "Available commands:"
      $stderr.puts commands.keys.map { |s| "  #{s}" }.join("\n")
      exit 1
    end

    return args
  end # def run

  def emit_version(args)
    require "logstash/version"
    puts "logstash #{LOGSTASH_VERSION}"

    # '-v' can be the only argument, end processing args now.
    return []
  end # def emit_version
end # class LogStash::Runner

if $0 == __FILE__
  LogStash::Runner.new.main(ARGV)
end
