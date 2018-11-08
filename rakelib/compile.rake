
rule ".rb" => ".treetop" do |task, args|
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"

  task "grammar" => "logstash-core/lib/logstash/config/grammar.rb"
  
  def safe_system(*args)
    if !system(*args)
      status = $?
      raise "Got exit status #{status.exitstatus} attempting to execute #{args.inspect}!"
    end
  end

  task "logstash-core-java" do
    puts("Building logstash-core using gradle")
    safe_system("./gradlew", "assemble")
  end

  desc "Build everything"
  task "all" => ["grammar", "logstash-core-java"]
end
