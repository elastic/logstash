# encoding: utf-8

RUNNER = File.join(File.expand_path(File.dirname(__FILE__)), "run.rb")
BASE_DIR = File.expand_path(File.dirname(__FILE__))

#
## script main

if ARGV.size != 1
  $stderr.puts("usage: ruby suite.rb [suite file]")
  exit(1)
end

@debug = !!ENV["DEBUG"]

tests = eval(IO.read(ARGV[0]))

tests.each do |test|
  duration = test[:events] ? ["--events", test[:events]] : ["--time", test[:time]]
  command = ["ruby", RUNNER, *duration, "--config", File.join(BASE_DIR, test[:config]), "--input", File.join(BASE_DIR, test[:input])]
  IO.popen(command.join(" "), "r") do |io|
    print("name=#{test[:name]}, ")
    io.each_line{|line| puts(line)}
  end
end
