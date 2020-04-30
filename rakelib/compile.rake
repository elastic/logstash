# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

rule ".rb" => ".treetop" do |task, args|
  require "treetop"
  compiler = Treetop::Compiler::GrammarCompiler.new
  compiler.compile(task.source, task.name)
  puts "Compiling #{task.source}"
end

namespace "compile" do
  desc "Compile the config grammar"
  task "grammar" => %w(
    logstash-core/lib/logstash/config/grammar.rb
    logstash-core/lib/logstash/compiler/lscl/lscl_grammar.rb
  )

  def safe_system(*args)
    if !system(*args)
      status = $?
      raise "Got exit status #{status.exitstatus} attempting to execute #{args.inspect}!"
    end
  end

  task "logstash-core-java" do
    unless File.exists?(File.join("logstash-core", "lib", "jars", "logstash-core.jar"))
      puts("Building logstash-core using gradle")
      safe_system("./gradlew", "assemble")
    end
  end

  desc "Build everything"
  task "all" => ["grammar", "logstash-core-java"]
end
