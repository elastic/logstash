# encoding: utf-8

require "benchmark"

INITIAL_MESSAGE = ">>> lorem ipsum start".freeze
LAST_MESSAGE = ">>> lorem ipsum stop".freeze
LOGSTASH_BIN = File.join(File.expand_path("../../../bin/", __FILE__), "logstash")

Thread.abort_on_exception = true

def feed_input_events(io, events_count, lines, last_message)
  loop_count = (events_count / lines.size).ceil # how many time we send the input file over

  (1..loop_count).each{lines.each {|line| io.puts(line)}}

  io.puts(last_message)
  io.flush

  loop_count * lines.size
end

def feed_input_interval(io, seconds, lines, last_message)
  loop_count = (2000 / lines.size).ceil # check time every ~2000(ceil) input lines
  lines_per_iteration = loop_count * lines.size
  start_time = Time.now
  count = 0

  while true
    (1..loop_count).each{lines.each {|line| io.puts(line)}}
    count += lines_per_iteration
    break if (Time.now - start_time) >= seconds
  end

  io.puts(last_message)
  io.flush

  count
end

def output_reader(io, regex)
  Thread.new(io, regex) do |io, regex|
    expect_output(io, regex)
  end
end

def read_input_file(file_path)
  IO.readlines(file_path).map(&:chomp)
end

def expect_output(io, regex)
  io.each_line do |line|
    puts("received: #{line}") if @debug
    break if line =~ regex
  end
end

#
## script main

# standalone quick & dirty options parsing
args = ARGV.dup
if args.size != 6
  $stderr.puts("usage: ruby run.rb --events [events count] --config [config file] --input [input file]")
  $stderr.puts("       ruby run.rb --time [seconds] --config [config file] --input [input file]")
  exit(1)
end

options = {}
while !args.empty?
  config = args.shift.to_s.strip
  option = args.shift.to_s.strip
  raise(IllegalArgumentException, "invalid option for #{config}") if option.empty?
  case config
  when "--events"
    options[:events] = option
  when "--time"
    options[:time] = option
  when "--config"
    options[:config] = option
  when "--input"
    options[:input] = option
  else
    raise(IllegalArgumentException, "invalid config #{config}")
  end
end

@debug = !!ENV["DEBUG"]

required_events_count = options[:events].to_i # total number of events to feed, independant of input file size
required_run_time = options[:time].to_i
input_lines = read_input_file(options[:input])

puts("will run with config file=#{options[:config]}, input file=#{options[:input]}") if @debug

command = [LOGSTASH_BIN, "-f", options[:config], "2>&1"]
puts("launching #{command.join(" ")}") if @debug

real_events_count = 0

IO.popen(command.join(" "), "r+") do |io|
  puts("sending initial event") if @debug
  io.puts(INITIAL_MESSAGE)
  io.flush

  puts("waiting for initial event") if @debug
  expect_output(io, /#{INITIAL_MESSAGE}/)

  puts("starting output reader thread") if @debug
  @reader = output_reader(io, /#{LAST_MESSAGE}/)
  puts("starting feeding input") if @debug

  elaspsed = Benchmark.realtime do
    real_events_count = if required_events_count > 0
      feed_input_events(io, [required_events_count, input_lines.size].max, input_lines, LAST_MESSAGE)
    else
      feed_input_interval(io, required_run_time, input_lines, LAST_MESSAGE)
    end

    puts("waiting for output reader to complete") if @debug
    @reader.join
  end

  puts("elaspsed=#{"%.2f" % elaspsed}s, events=#{real_events_count}, tps=#{"%.0f" % (real_events_count / elaspsed)}")
end
