# Monkeypatch for JRUBY-6970
module Kernel
  alias_method :require_JRUBY_6970_hack, :require

  def require(path)
    if path =~ /^jar:file:.+!.+/
      path = path.gsub(/^jar:/, "")
      puts "JRUBY-6970: require(#{path})" if ENV["REQUIRE_DEBUG"] == "1"
    end
    return require_JRUBY_6970_hack(path)
  end
end

require "rubygems"
require "logstash/namespace"
require "logstash/program"
require "logstash/util"

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
              if File.exists?(newpath)
                # Add the 'spec' dir to the load path so specs can run
                specpath = File.join(jar_root, "spec")
                $: << specpath unless $:.include?(specpath)
                newpath
              else
                arg
              end
            else
              arg
            end
          else
            arg
          end
        end # args.collect
        RSpec::Core::Runner.run(fixedargs)
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
