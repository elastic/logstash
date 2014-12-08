# encoding: utf-8

require 'test/integration/run'

RUNNER = File.join(File.expand_path(File.dirname(__FILE__)), "run.rb")
BASE_DIR = File.expand_path(File.dirname(__FILE__))

## script main

if ARGV.size != 1
  $stderr.puts("usage: ruby suite.rb [suite file]")
  exit(1)
end

@debug = !!ENV["DEBUG"]

tests = eval(IO.read(ARGV[0]))
lines = ["name, #{Runner.headers.join(',')}"]
first = true

reporter = Thread.new do
  loop do
    $stderr.print "."
    sleep 1
  end
end

tests.each do |test|

  events = test[:events].to_i # total number of events to feed, independant of input file size
  time   = test[:time].to_i
  config = File.join(BASE_DIR, test[:config])
  input  = File.join(BASE_DIR, test[:input])

  runner = Runner.new(config, @debug)
  p, elaspsed, events_count = runner.run(events, time, runner.read_input_file(input))

  lines << "#{test[:name]}, #{"%.2f" % elaspsed}, #{events_count}, #{"%.0f" % (events_count / elaspsed)},#{p.last}, #{"%.0f" % (p.reduce(:+) / p.size)}"
  first = false
end

reporter.kill
puts lines.join("\n")
