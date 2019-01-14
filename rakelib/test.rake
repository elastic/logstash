# we need to call exit explicitly  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"
require 'pathname'

namespace "test" do

  desc "run the java unit tests"
  task "core-java" do
    exit(1) unless system('./gradlew clean javaTests')
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
  task "core-slow" do
    exit 1 unless system('./gradlew clean test')
  end

  desc "run core specs excluding slower tests like stress tests"
  task "core-fast" do
    exit 1 unless system(*(default_spec_command.concat(["--tag", "~stress_test"])))
  end

  desc "run all installed plugins specs"
  task "plugins"  => "bootstrap" do
    plugins_to_exclude = ENV.fetch("EXCLUDE_PLUGIN", "").split(",")
    # grab all spec files using the live plugins gem specs. this allows correctly also running the specs
    # of a local plugin dir added using the Gemfile :path option. before this, any local plugin spec would
    # not be run because they were not under the vendor/bundle/jruby/2.0/gems path
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
    exit 1 unless system(*(["bin/rspec", "-fd", "--order", "rand"].concat(test_files)))
  end

  desc "install core plugins and dev dependencies"
  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  desc "install default plugins and dev dependencies"
  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  desc "install vendor plugins and dev dependencies"
  task "install-vendor-plugins" => ["bootstrap", "plugin:install-vendor", "plugin:install-development-dependencies"]

  desc "install jar dependencies and dev dependencies"
  task "install-jar-dependencies-plugins" => ["bootstrap", "plugin:install-jar-dependencies", "plugin:install-development-dependencies"]
end

task "test" => [ "test:core" ]
