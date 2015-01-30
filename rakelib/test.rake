
namespace "test" do
  task "default" => [ "bootstrap:test", "test:prep" ] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(Rake::FileList["spec/**/*.rb"])
  end

  task "fail-fast" => [ "bootstrap:test", "test:prep" ] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(["--fail-fast", *Rake::FileList["spec/**/*.rb"]])
  end

  task "all-plugins" => [ "bootstrap","plugin:install-all" ] do
    Rake::Task["test:plugins"].invoke
  end

  task "plugins" => [ "bootstrap", "plugin:install-defaults" ] do
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    pattern = "#{gem_home}/gems/logstash-*/spec/{input,filter,codec,output}s/*_spec.rb"
    gem_home = LogStash::Environment.logstash_gem_home
    RSpec::Core::Runner.run(Rake::FileList[pattern])
    #sh "#{LogStash::Environment::LOGSTASH_HOME}/bin/logstash rspec --order rand #{pattern}"
  end

  task "prep" do
    Rake::Task["vendor:gems"].invoke(false)
    Rake::Task["plugin:install-test"].invoke
  end

end

task "test" => [ "test:default" ]
