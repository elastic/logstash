
rule ".rb" => ".treetop" do |task, args|
  # TODO(sissel): Treetop 1.5.x doesn't seem to work well, but I haven't
  # investigated what the cause might be. -Jordan
  Rake::Task["gem:require"].invoke("treetop", "~> 1.4.0", ENV["GEM_HOME"])
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"
  task "grammar" => "lib/logstash/config/grammar.rb"

  desc "Build everything"
  task "all" => "grammar"
end
