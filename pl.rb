# pipeline tests

$: << "lib"
require "logstash/config/file"
config = LogStash::Config::File.new(nil, ARGV[0])
agent = LogStash::Agent.new
inputs, filters, outputs = agent.instance_eval { parse_config(config) }

inputs.collect(&:register)
filters.collect(&:register)
outputs.collect(&:register)

i2f = SizedQueue.new(16)
f2o  = SizedQueue.new(16)
i2f = f2o if filters.empty?

input_threads = inputs.collect do |i| 
  t = Thread.new do
    begin
      i.run(i2f)
    rescue => e
      puts :input => i.class, :exception => e
    end
  end
  t[:name] = i.class
  t
end

#input_supervisor_thread = Thread.new do
  #while true 
    #input_threads.collect(&:join)
    #i2f << :shutdown
  #end
#end

filter_thread = Thread.new(filters) do |filters|
  if filters.any?
    event = i2f.pop
    filters.each do |filter|
      filter.filter(event)
    end
    f2o << event
  end
end
filter_thread[:name] = "filterworker"

output_thread = Thread.new do
  begin
    while true 
      event = f2o.pop
      outputs.each do |output|
        output.receive(event)
      end
    end
  rescue => e
    puts :output_thread => e
  end
end
output_thread[:name] = "outputworker"

def twait(thread)
  begin
    puts :waiting => thread[:name]
    thread.join
    puts :donewaiting => thread[:name]
  rescue => e
    puts thread => e
  end
end

def shutdown(input, filter, output)
  input.each do |i|
    i.raise("SHUTDOWN")
    twait(i)
  end

  #filter.raise("SHUTDOWN")
  #twait(filter)
  output.raise("SHUTDOWN")
  twait(output)
end

trap("INT") do
  puts "SIGINT"; shutdown(input_threads, filter_thread, output_thread)
  exit 1
end

#[*input_threads, filter_thread, output_thread].collect(&:join)
sleep 30


