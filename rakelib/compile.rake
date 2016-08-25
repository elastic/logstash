
rule ".rb" => ".treetop" do |task, args|
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"

  task "grammar" => "logstash-core/lib/logstash/config/grammar.rb"

  task "logstash-core-java" do
    puts("Building logstash-core using gradle")
    system("./gradlew", "vendor", "-p", "./logstash-core")
  end

  task "logstash-core-event-java" do
    puts("Building logstash-core-event-java using gradle")
    system("./gradlew", "jar", "-p", "./logstash-core-event-java")
  end

  desc "Build everything"
  task "all" => ["grammar", "logstash-core-java", "logstash-core-event-java"]
end
