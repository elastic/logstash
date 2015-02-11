
namespace "test" do
  task "default" => ["bootstrap", "test:prep"] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require "rspec/core/runner"
    require "rspec"
    RSpec::Core::Runner.run(Rake::FileList["spec/**/*.rb"])
  end

  task "fail-fast" => ["bootstrap", "test:prep"] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(["--fail-fast", *Rake::FileList["spec/**/*.rb"]])
  end

  task "all-plugins" => ["bootstrap"] do
    Rake::Task["plugin:plugin:install-all"].invoke
    Rake::Task["plugin:install-development-dependencies"].invoke
    Rake::Task["test:plugins"].invoke
  end

  task "plugins" => ["bootstrap"] do
    gem_root = ENV["GEM_HOME"]
    pattern = File.join(*"gems/logstash-*/spec/{input,filter,codec,output}s/*_spec.rb".split("/"))
    sh "#{LogStash::Environment::LOGSTASH_HOME}/bin/logstash rspec --order rand #{gem_root} -P '#{pattern}'"
  end

  task "prep" do
    # Rake::Task["vendor:gems"].invoke(false)
    Rake::Task["plugin:install-test"].invoke
    Rake::Task["plugin:install-development-dependencies"].invoke
  end
end

task "test" => [ "test:default" ]
