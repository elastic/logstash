require "rubygems"
require "logstash/namespace"

class LogStash::Runner
  def main(args)
    $: << File.join(File.dirname(__FILE__), "../")

    @runners = []
    while !args.empty?
      #p :args => args
      args = run(args)
    end

    @runners.each { |r| r.wait }
  end # def self.main

  def run(args)
    command = args.shift
    commands = {
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
        require "logstash_test_runner"
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
  end # def self.run
end # class LogStash::Runner

if $0 == __FILE__
  LogStash::Runner.new.main(ARGV)
end
