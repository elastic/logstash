
$: << File.join(File.dirname(__FILE__), "../")
command = ARGV.shift

case command
when "agent"
  require "logstash/agent"
  agent = LogStash::Agent.new
  agent.argv = ARGV
  agent.run
when "web"
  puts "not supported yet"
when "test"
  puts "not supported yet"
end
