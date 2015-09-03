# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"

namespace "test" do

  task "setup" do
    # Need to be run here as because if run aftewarse (after the bundler.setup task) then the report got wrong
    # numbers and misses files. There is an issue with our setup! method as this does not happen with the regular
    # bundler.setup used in regular bundler flows.
    Rake::Task["test:setup-simplecov"].invoke if ENV['COVERAGE']

    require "bootstrap/environment"
    LogStash::Bundler.setup!({:without => [:build]})

    require "rspec/core/runner"
    require "rspec"
    require 'ci/reporter/rake/rspec_loader'
  end

  desc "run core specs"
  task "core" => ["setup"] do
    exit(RSpec::Core::Runner.run([Rake::FileList["spec/**/*_spec.rb"]]))
  end

  desc "run core specs in fail-fast mode"
  task "core-fail-fast" => ["setup"] do
    exit(Spec::Core::Runner.run(["--fail-fast", Rake::FileList["spec/**/*_spec.rb"]]))
  end

  desc "run core specs on a single file"
  task "core-single-file", [:specfile] => ["setup"] do |t,args|
    exit(RSpec::Core::Runner.run([Rake::FileList[args.specfile]]))
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

  # Setup simplecov to group files per functional modules, like this is easier to spot places with small coverage
  task "setup-simplecov" do
    require "simplecov"
    SimpleCov.start do
      # Skip non core related directories and files.
      ["vendor/", "spec/", "bootstrap/rspec", "Gemfile", "gemspec"].each do |pattern|
        add_filter pattern
      end

      add_group "bootstrap", "bootstrap/" # This module is used during bootstraping of LS
      add_group "plugin manager", "pluginmanager/" # Code related to the plugin manager
      add_group "core" do |src_file| # The LS core codebase
        /logstash\/\w+.rb/.match(src_file.filename)
      end
      add_group "core-util", "logstash/util" # Set of LS utils module
      add_group "core-config", "logstash/config" # LS Configuration modules
      add_group "core-patches", "logstash/patches" # Patches used to overcome known issues in dependencies.
      # LS Core plugins code base.
      add_group "core-plugins", [ "logstash/codecs", "logstash/filters", "logstash/outputs", "logstash/inputs" ]
    end
    task.reenable
  end

end

task "test" => [ "test:core" ]
