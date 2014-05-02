# encoding: utf-8

Encoding.default_external = Encoding::UTF_8
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

require "logstash/monkeypatches-for-debugging"
require "logstash/namespace"
require "logstash/program"
require "i18n" # gem 'i18n'
I18n.enforce_available_locales = true
I18n.load_path << File.expand_path(
  File.join(File.dirname(__FILE__), "../../locales/en.yml")
)

class LogStash::RSpecsRunner
  def initialize(args)
    @args = args
  end

  def run
    @result = RSpec::Core::Runner.run(@args)
  end

  def wait
    return @result
  end
end

class LogStash::Runner
  include LogStash::Program

  def initialize
    @runners = []
  end

  def main(args)
    require "logstash/util"
    require "stud/trap"
    require "stud/task"
    @startup_interruption_trap = Stud::trap("INT") { puts "Interrupted"; exit 0 }

    LogStash::Util::set_thread_name(self.class.name)
    #$LOAD_PATH << File.join(File.dirname(__FILE__), "..")

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    Stud::untrap("INT", @startup_interruption_trap)

    args = [nil] if args.empty?

    while args != nil && !args.empty?
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
      "version" => lambda do
        require "logstash/agent"
        agent_args = ["--version"]
        if args.include?("--verbose")
          agent_args << "--verbose"
        end
        LogStash::Agent.run($0, agent_args)
        return []
      end,
      "web" => lambda do
        # Give them kibana.
        require "logstash/kibana"
        kibana = LogStash::Kibana::Runner.new
        @runners << kibana
        return kibana.run(args)
      end,
      "rspec" => lambda do
        require "rspec/core/runner"
        require "rspec"
        spec_path = File.expand_path(File.join(File.dirname(__FILE__), "/../../spec"))
        $LOAD_PATH << spec_path
        require "test_utils"
        all_specs = Dir.glob(File.join(spec_path, "/**/*.rb"))
        rspec = LogStash::RSpecsRunner.new(args.empty? ? all_specs : args)
        rspec.run
        @runners << rspec
        return []
      end,
      "irb" => lambda do
        require "irb"
        IRB.start(__FILE__)
        return []
      end,
      "ruby" => lambda do
        require(args[0])
        return []
      end,
      "pry" => lambda do
        require "pry"
        return binding.pry
      end,
      "agent" => lambda do
        require "logstash/agent"
        # Hack up a runner
        agent = LogStash::Agent.new($0)
        begin
          agent.parse(args)
        rescue Clamp::HelpWanted => e
          show_help(e.command)
          return []
        rescue Clamp::UsageError => e
          # If 'too many arguments' then give the arguments to
          # the next command. Otherwise it's a real error.
          raise if e.message != "too many arguments"
          remaining = agent.remaining_arguments
        end
        @runners << Stud::Task.new { agent.execute }

        return remaining
      end
    } # commands

    if commands.include?(command)
      args = commands[command].call
    else
      if command.nil?
        $stderr.puts "No command given"
      else
        if !%w(--help -h help).include?(command)
          # Emit 'no such command' if it's not someone asking for help.
          $stderr.puts "No such command #{command.inspect}"
        end
      end
      $stderr.puts "Usage: logstash <command> [command args]"
      $stderr.puts "Run a command with the --help flag to see the arguments."
      $stderr.puts "For example: logstash agent --help"
      $stderr.puts
      # hardcode the available commands to reduce confusion.
      $stderr.puts "Available commands:"
      $stderr.puts "  agent - runs the logstash agent"
      $stderr.puts "  version - emits version info about this logstash"
      $stderr.puts "  web - runs the logstash web ui (called Kibana)"
      $stderr.puts "  rspec - runs tests"
      #$stderr.puts commands.keys.map { |s| "  #{s}" }.join("\n")
      exit 1
    end

    return args
  end # def run

  # @return true if this file is the main file being run and not via rspec
  def self.autorun?
    # caller is the current execution stack
    $0 == __FILE__ && caller.none?{|entry| entry =~ /rspec/}
  end

  private

  def show_help(command)
    puts command.help
  end
end # class LogStash::Runner

LogStash::Runner.new.main(ARGV) if LogStash::Runner.autorun?
