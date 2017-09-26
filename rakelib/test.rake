# we need to call exit explicitly  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"

namespace "test" do

  desc "run the java unit tests"
  task "core-java" do
    exit(1) unless system './gradlew clean test'
  end

  desc "run the ruby unit tests"
  task "core-ruby" do
    exit 1 unless system(*default_spec_command)
  end

  desc "run all core specs"
  task "core" => ["core-slow"]
  
  def default_spec_command
    ["bin/rspec", "-fd", "--pattern", "spec/unit/**/*_spec.rb,logstash-core/spec/**/*_spec.rb"]
  end

  desc "run all core specs"
  task "core-slow" => ["core-java"] do
    exit 1 unless system(*default_spec_command)
  end

  desc "run core specs excluding slower tests like stress tests"
  task "core-fast" do
    exit 1 unless system(*(default_spec_command.concat(["--tag", "~stress_test"])))
  end

  desc "run all core specs in fail-fast mode"
  task "core-fail-fast" do
    exit 1 unless system(*(default_spec_command.concat(["--fail-fast"])))
  end
  
  desc "run all installed plugins specs"
  task "plugins" do
    plugins_to_exclude = ENV.fetch("EXCLUDE_PLUGIN", "").split(",")
    # grab all spec files using the live plugins gem specs. this allows correctly also running the specs
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

  desc "install core plugins and dev dependencies"
  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  desc "install default plugins and dev dependencies"
  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  task "install-all" => ["bootstrap", "plugin:install-all", "plugin:install-development-dependencies"]
  
  desc "install vendor plugins and dev dependencies"
  task "install-vendor-plugins" => ["bootstrap", "plugin:install-vendor", "plugin:install-development-dependencies"]

  desc "install jar dependencies and dev dependencies"
  task "install-jar-dependencies-plugins" => ["bootstrap", "plugin:install-jar-dependencies", "plugin:install-development-dependencies"]

  # Setup simplecov to group files per functional modules, like this is easier to spot places with small coverage
  task "setup-simplecov" do
    require "simplecov"
    SimpleCov.start do
      # Skip non core related directories and files.
      ["vendor/", "spec/", "bootstrap/rspec", "Gemfile", "gemspec"].each do |pattern|
        add_filter pattern
      end

      add_group "bootstrap", "bootstrap/" # This module is used during bootstrapping of LS
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
