
rule ".rb" => ".treetop" do |task, args|
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"

  # TODO: (colin) temporary fix for logstash-core
  task "grammar" => "logstash-core/lib/logstash/config/grammar.rb"

  desc "Build everything"
  task "all" => "grammar"
end
