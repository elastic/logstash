
$START = Time.now
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

Thread.abort_on_exception = true
if ENV["PROFILE_BAD_LOG_CALLS"] || $DEBUGLIST.include?("log")
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
end # PROFILE_BAD_LOG_CALLS

require "logstash/monkeypatches-for-performance"
require "logstash/monkeypatches-for-bugs"
require "logstash/monkeypatches-for-debugging"
require "logstash/namespace"
require "logstash/program"
require "i18n" # gem 'i18n'
I18n.load_path << File.expand_path(
  File.join(File.dirname(__FILE__), "../../locales/en.yml")
)

class LogStash::Runner
  include LogStash::Program

  def main(args)
    require "logstash/util"
    require "stud/trap"
    @startup_interruption_trap = Stud::trap("INT") { puts "Interrupted"; exit 0 }

    LogStash::Util::set_thread_name(self.class.name)
    $: << File.join(File.dirname(__FILE__), "..")

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    Stud::untrap("INT", @startup_interruption_trap)

    args = [nil] if args.empty?

    @runners = []
    while !args.empty?
      args = run(args)
    end

    status = []
    @runners.each do |r|
      #$stderr.puts "Waiting on #{r.wait.inspect}"
      status << r.wait
    end

    # Avoid running test/unit's at_exit crap
    if status.empty? || status.first.nil?
      exit(0)
    else
      exit(status.first)
    end
  end # def self.main

  def run(args)
    command = args.shift
    commands = {
      "version" => lambda { emit_version(args) },
      "web" => lambda do
        require "logstash/web/runner"
        web = LogStash::Web::Runner.new
        @runners << web
        return web.run(args)
      end,
      "kibana" => lambda do
        require "logstash/kibana"
        kibana = LogStash::Kibana::Runner.new
        @runners << kibana
        return kibana.run(args)
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
              newpath = File.join(jar_root, arg)

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
      end,
      "agent" => lambda do
        require "logstash/agent"
        # Hack up a runner
        runner = Class.new do
          def initialize(args)
            @args = args
          end
          def run
            #@thread = Thread.new do
              @result = LogStash::Agent.run($0, @args)
            #end
          end
          def wait
            #@thread.join
            return @result
          end
        end

        agent = runner.new(args)
        agent.run
        #@runners << agent
        return []
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
      $stderr.puts "Usage: logstash <command> [command args]"
      $stderr.puts "Run a command with the --help flag to see the arguments."
      $stderr.puts "For example: logstash agent --help"
      $stderr.puts
      # hardcode the available commands to reduce confusion.
      $stderr.puts "Available commands:"
      $stderr.puts "  agent - runs the logstash agent"
      $stderr.puts "  version - emits version info about this logstash"
      $stderr.puts "  web - runs the logstash web ui"
      $stderr.puts "  kibana - runs the kibana web ui"
      $stderr.puts "  rspec - runs tests"
      #$stderr.puts commands.keys.map { |s| "  #{s}" }.join("\n")
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
