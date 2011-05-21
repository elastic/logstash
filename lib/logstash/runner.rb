require "rubygems"
require "logstash/namespace"

class LogStash::Runner
  def self.main(args)
    $: << File.join(File.dirname(__FILE__), "../")
    command = args.shift

    commands = {
      "agent" => proc do
        require "logstash/agent"
        agent = LogStash::Agent.new
        agent.argv = args
        agent.run
      end,
      "web" => proc do
        require "logstash/web/server"
      end,
      "test" => proc do
        require "logstash_test_runner"
      end
    }

    if commands.include?(command)
      commands[command].call
    else
      $stderr.puts "No such command #{command.inspect}"
      $stderr.puts "Available commands:"
      $stderr.puts commands.keys.map { |s| "  #{s}" }.join("\n")
      exit 1
    end
  end # def self.main
end # class LogStash::Runner

if $0 == __FILE__
  LogStash::Runner.main(ARGV)
end
