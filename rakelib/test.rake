# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"

namespace "test" do

  task "setup" do

    # make sure we have a ./data/queue dir here
    # temporary wiring until we figure proper queue initialization sequence and in test context etc.
    mkdir "data" unless File.directory?("data")
    mkdir "data/queue" unless File.directory?("data/queue")

    # Need to be run here as because if run aftewarse (after the bundler.setup task) then the report got wrong
    # numbers and misses files. There is an issue with our setup! method as this does not happen with the regular
    # bundler.setup used in regular bundler flows.
    Rake::Task["test:setup-simplecov"].invoke if ENV['COVERAGE']

    require "bootstrap/environment"
    LogStash::Bundler.setup!({:without => [:build]})
    require "logstash-core"

    require "rspec/core/runner"
    require "rspec"
    require 'ci/reporter/rake/rspec_loader'
  end

  def core_specs
    # note that regardless if which logstash-core-event-* gem is live, we will always run the
    # logstash-core-event specs since currently this is the most complete Event and Timestamp specs
    # which actually defines the Event contract and should pass regardless of the actuall underlying
    # implementation.
    specs = ["spec/unit/**/*_spec.rb", "logstash-core/spec/**/*_spec.rb", "logstash-core-event/spec/**/*_spec.rb"]

    # figure if the logstash-core-event-java gem is loaded and if so add its specific specs in the core specs to run
    begin
      require "logstash-core-event-java/version"
      specs << "logstash-core-event-java/spec/**/*_spec.rb"
    rescue LoadError
      # logstash-core-event-java gem is not live, ignore and skip specs
    end

    Rake::FileList[*specs]
  end

  desc "run core specs"
  task "core" => ["setup"] do
    exit(RSpec::Core::Runner.run([core_specs]))
  end

  desc "run core specs in fail-fast mode"
  task "core-fail-fast" => ["setup"] do
    exit(RSpec::Core::Runner.run(["--fail-fast", core_specs]))
  end

  desc "run core specs on a single file"
  task "core-single-file", [:specfile] => ["setup"] do |t, args|
    exit(RSpec::Core::Runner.run([Rake::FileList[args.specfile]]))
  end

  desc "run all installed plugins specs"
  task "plugins" => ["setup"] do
    plugins_to_exclude = ENV.fetch("EXCLUDE_PLUGIN", "").split(",")
    # grab all spec files using the live plugins gem specs. this allows correclty also running the specs
    # of a local plugin dir added using the Gemfile :path option. before this, any local plugin spec would
    # not be run because they were not under the vendor/bundle/jruby/1.9/gems path
    test_files = LogStash::PluginManager.find_plugins_gem_specs.map do |spec|
      if plugins_to_exclude.size > 0
        if !plugins_to_exclude.include?(Pathname.new(spec.gem_dir).basename.to_s)
          Rake::FileList[File.join(spec.gem_dir, "spec/{input,filter,codec,output}s/*_spec.rb")]
        end
      else
        Rake::FileList[File.join(spec.gem_dir, "spec/{input,filter,codec,output}s/*_spec.rb")]
      end
    end.flatten.compact

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
