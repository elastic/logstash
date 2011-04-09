require "rubygems"

$: << File.join(File.dirname(__FILE__), "../")
command = ARGV.shift

commands = {
  "agent" => proc do
    require "logstash/agent"
    agent = LogStash::Agent.new
    agent.argv = ARGV
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
