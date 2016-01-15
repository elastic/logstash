
rule ".rb" => ".treetop" do |task, args|
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"

  task "grammar" => "logstash-core/lib/logstash/config/grammar.rb"

  task "logstash-core-event-java" do
    puts("Building logstash-core-event-java using gradle")
    system("logstash-core-event-java/gradlew", "jar", "-p", "./logstash-core-event-java")
  end

  desc "Build everything"
  task "all" => ["grammar", "logstash-core-event-java"]
end
