
namespace "test" do
  task "default" => [ "bootstrap", "test:prep" ] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(Rake::FileList["spec/**/*.rb"])
  end

  task "fail-fast" => [ "bootstrap", "test:prep" ] do
    Gem.clear_paths
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(["--fail-fast", *Rake::FileList["spec/**/*.rb"]])
  end

  task "prep" do
    Rake::Task["plugin:install-test"].invoke
  end

end

task "test" => [ "test:default" ]
