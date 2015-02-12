
namespace "test" do
  task "core" do
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require "rspec/core/runner"
    require "rspec"
    RSpec::Core::Runner.run(Rake::FileList["spec/**/*.rb"])
  end

  task "core-fail-fast" do
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require "rspec/core/runner"
    require "rspec"
    RSpec::Core::Runner.run(["--fail-fast", *Rake::FileList["spec/**/*.rb"]])
  end

  task "plugins" do
    gem_root = ENV["GEM_HOME"]
    pattern = File.join(*"gems/logstash-*/spec/{input,filter,codec,output}s/*_spec.rb".split("/"))
    sh "#{LogStash::Environment::LOGSTASH_HOME}/bin/logstash rspec --order rand #{gem_root} -P '#{pattern}'"
  end

  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  task "install-all" => ["bootstrap", "plugin:install-all", "plugin:install-development-dependencies"]
end

task "test" => [ "test:core" ]
