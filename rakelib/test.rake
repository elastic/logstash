##
# In Logstash we use rspec throw the runner interface so we need to
# call explicity to exit in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.
# In general this is not a problem, because the most common rspec usage
# is throw the rake task, where rspec sets this himself internally.
##
namespace "test" do
  def run_rspec(*args)
    require "logstash/environment"
    LogStash::Environment.bundler_setup!({:without => []})
    require "rspec/core/runner"
    require "rspec"
    RSpec::Core::Runner.run([*args])
  end

  task "core" do
    exit run_rspec(Rake::FileList["spec/**/*_spec.rb"])
  end

  task "core-fail-fast" do
    exit run_rspec("--fail-fast", Rake::FileList["spec/**/*_spec.rb"])
  end

  task "plugins" do
    exit run_rspec("--order", "rand", Rake::FileList[File.join(ENV["GEM_HOME"], "gems/logstash-*/spec/{input,filter,codec,output}s/*_spec.rb")])
  end

  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  task "install-all" => ["bootstrap", "plugin:install-all", "plugin:install-development-dependencies"]

  task "install-vendor-plugins" => ["bootstrap", "plugin:install-vendor", "plugin:install-development-dependencies"]

  task "install-jar-dependencies-plugins" => ["bootstrap", "plugin:install-jar-dependencies", "plugin:install-development-dependencies"]
end

task "test" => [ "test:core" ]
