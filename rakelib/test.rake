
namespace "test" do
  task "default" => [ "bootstrap", "test:prep" ] do
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(Rake::FileList["spec/**/*.rb"])
  end

  task "fail-fast" => [ "bootstrap", "test:prep" ] do
    require "logstash/environment"
    LogStash::Environment.set_gem_paths!
    require 'rspec/core'
    RSpec::Core::Runner.run(["--fail-fast", *Rake::FileList["spec/**/*.rb"]])
  end

  task "prep" do
    plugins = [
     'logstash-filter-clone',
     'logstash-filter-mutate',
     'logstash-input-generator',
     'logstash-input-stdin',
     'logstash-input-tcp',
     'logstash-output-stdout'
    ]
    Rake::Task["plugin:install"].invoke(plugins)
  end

end

task "test" => [ "test:default" ] 
