# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"

namespace "test" do
  task "setup" do
    require "bootstrap/environment"
    LogStash::Bundler.setup!({:without => []})

    require "rspec/core/runner"
    require "rspec"
  end

  desc "run core specs"
  task "core" => ["setup"] do
    exit(RSpec::Core::Runner.run([Rake::FileList["spec/**/*_spec.rb"]]))
  end

  desc "run core specs in fail-fast mode"
  task "core-fail-fast" => ["setup"] do
    exit(Spec::Core::Runner.run(["--fail-fast", Rake::FileList["spec/**/*_spec.rb"]]))
  end

  desc "run all installed plugins specs"
  task "plugins" => ["setup"] do
    # grab all spec files using the live plugins gem specs. this allows correclty also running the specs
    # of a local plugin dir added using the Gemfile :path option. before this, any local plugin spec would
    # not be run because they were not under the vendor/bundle/jruby/1.9/gems path
    test_files = LogStash::PluginManager.find_plugins_gem_specs.map do |spec|
      Rake::FileList[File.join(spec.gem_dir, "spec/{input,filter,codec,output}s/*_spec.rb")]
    end.flatten

    # "--format=documentation"
    exit(RSpec::Core::Runner.run(["--order", "rand", test_files]))
  end

  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  task "install-all" => ["bootstrap", "plugin:install-all", "plugin:install-development-dependencies"]

  task "install-vendor-plugins" => ["bootstrap", "plugin:install-vendor", "plugin:install-development-dependencies"]

  task "install-jar-dependencies-plugins" => ["bootstrap", "plugin:install-jar-dependencies", "plugin:install-development-dependencies"]
end

task "test" => [ "test:core" ]
