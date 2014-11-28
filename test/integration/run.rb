# encoding: utf-8

require "benchmark"
require "thread"
require "open3"

require 'test/integration/stats'

INITIAL_MESSAGE = ">>> lorem ipsum start".freeze
LAST_MESSAGE = ">>> lorem ipsum stop".freeze

Thread.abort_on_exception = true

class Runner

  LOGSTASH_BIN  = File.join(File.expand_path("../../../bin/", __FILE__), "logstash").freeze
  REFRESH_COUNT = 100

  attr_reader :command

  def initialize(config, debug=false)
    @debug = debug
    @command = [LOGSTASH_BIN, "-f", config]
  end


  def run(required_events_count, required_run_time, input_lines)
    puts("launching #{command.join(" ")}") if @debug
    stats = Stats.new
    real_events_count = 0
    Open3.popen3(*@command) do |i, o, e|
      puts("sending initial event") if @debug
      i.puts(INITIAL_MESSAGE)
      i.flush

      puts("waiting for initial event") if @debug
      expect_output(o, /#{INITIAL_MESSAGE}/)

      puts("starting output reader thread") if @debug
      reader = stats.detach_output_reader(o, /#{LAST_MESSAGE}/)
      puts("starting feeding input") if @debug

      elaspsed = Benchmark.realtime do
        real_events_count = if required_events_count > 0
                              feed_input_events(i, [required_events_count, input_lines.size].max, input_lines, LAST_MESSAGE)
                            else
                              feed_input_interval(i, required_run_time, input_lines, LAST_MESSAGE)
                            end

        puts("waiting for output reader to complete") if @debug
        reader.join
      end
      p = percentile(stats.stats, 0.80)
      [p, elaspsed, real_events_count]
    end
  end

  def read_input_file(file_path)
    IO.readlines(file_path).map(&:chomp)
  end


  private

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

  def expect_output(io, regex)
    io.each_line do |line|
      puts("received: #{line}") if @debug
      yield if block_given?
      break if line =~ regex
    end
  end

  def percentile(array, percentile)
    count = (array.length * (1.0 - percentile)).floor
    array.sort[-count..-1]
  end

end

#
## script main

# standalone quick & dirty options parsing
args = ARGV.dup
if args.size != 8
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
  when "--headers"
    options[:headers] = option
  else
    raise(IllegalArgumentException, "invalid config #{config}")
  end
end

@debug = !!ENV["DEBUG"]

required_events_count = options[:events].to_i # total number of events to feed, independant of input file size
required_run_time = options[:time].to_i
add_headers       = options[:headers]

puts("using config file=#{options[:config]}, input file=#{options[:input]}") if @debug

runner = Runner.new(options[:config], @debug)
p, elaspsed, real_events_count = runner.run(required_events_count, required_run_time, runner.read_input_file(options[:input]))
puts("elaspsed, events, avg tps, best tps, avg top 20% tps") if add_headers
puts("#{"%.2f" % elaspsed}, #{real_events_count}, #{"%.0f" % (real_events_count / elaspsed)},#{p.last}, #{"%.0f" % (p.reduce(:+) / p.size)}")

