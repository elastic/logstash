
rule ".rb" => ".treetop" do |task, args|
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

  task "jruby-event" do
    sh './java/gradlew logstash-event:shadowJar -p ./java'
  end
end
