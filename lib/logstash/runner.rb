# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "logstash/environment"

LogStash::Environment.load_locale!

require "logstash/namespace"
require "logstash/program"

class LogStash::Runner
  include LogStash::Program

  def main(args)
    require "logstash/util"
    require "logstash/util/java_version"
    require "stud/trap"
    require "stud/task"
    @startup_interruption_trap = Stud::trap("INT") { puts "Interrupted"; exit 0 }

    LogStash::Util::set_thread_name(self.class.name)

    if RUBY_VERSION < "1.9.2"
      $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      return 1
    end

    # Print a warning to STDERR for bad java versions
    LogStash::Util::JavaVersion.warn_on_bad_java_version

    Stud::untrap("INT", @startup_interruption_trap)

    task = run(args)
    exit(task.wait)
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
        return LogStash::Agent.run($0, agent_args)
      end,
      "irb" => lambda do
        require "irb"
        return IRB.start(__FILE__)
      end,
      "pry" => lambda do
        require "pry"
        return binding.pry
      end,
      "docgen" => lambda do
        require 'docs/asciidocgen'
        opts = OptionParser.new
        settings = {}
        opts.on("-o DIR", "--output DIR",
          "Directory to output to; optional. If not specified,"\
          "we write to stdout.") do |val|
          settings[:output] = val
        end
        args = opts.parse(ARGV)
        docs = LogStashConfigAsciiDocGenerator.new
        args.each do |arg|
          docs.generate(arg, settings)
        end
        return 0
      end,
      "agent" => lambda do
        require "logstash/agent"
        # Hack up a runner
        agent = LogStash::Agent.new("/bin/logstash agent", $0)
        begin
          agent.parse(args)
        rescue Clamp::HelpWanted => e
          show_help(e.command)
          return 0
        rescue Clamp::UsageError => e
          # If 'too many arguments' then give the arguments to
          # the next command. Otherwise it's a real error.
          raise if e.message != "too many arguments"
          remaining = agent.remaining_arguments
        end

        return agent.execute
      end
    } # commands

    if commands.include?(command)
      return Stud::Task.new { commands[command].call }
    else
      if command.nil?
        $stderr.puts "No command given"
      else
        if !%w(--help -h help).include?(command)
          # Emit 'no such command' if it's not someone asking for help.
          $stderr.puts "No such command #{command.inspect}"
        end
      end
      $stderr.puts %q[
Usage: logstash <command> [command args]
Run a command with the --help flag to see the arguments.
For example: logstash agent --help

Available commands:
  agent - runs the logstash agent
  version - emits version info about this logstash
]
      #$stderr.puts commands.keys.map { |s| "  #{s}" }.join("\n")
      return Stud::Task.new { 1 }
    end
  end # def run

  private

  def show_help(command)
    puts command.help
  end
end # class LogStash::Runner
