# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require "pluginmanager/util"
require "rake/rspec"

namespace "test" do

  desc "run core specs, using the local logstash-core gems"
  task "core" do
    exit(LogStash::RSpec.run_with_local_core_gems([LogStash::RSpec.core_specs]))
  end

  desc "run core specs in fail-fast mode, using the local logstash-core gems"
  task "core-fail-fast" do
    exit(LogStash::RSpec.run_with_local_core_gems(["--fail-fast", LogStash::RSpec.core_specs]))
  end

  desc "run core specs on a single file, using the local logstash-core gems"
  task "core-single-file", [:specfile] do |t, args|
    exit(LogStash::RSpec.run_with_local_core_gems([Rake::FileList[args.specfile]]))
  end

  namespace "released" do

    desc "run core specs, using the released logstash-core gem"
    task "core" do
      exit(LogStash::RSpec.run([LogStash::RSpec.core_specs]))
    end

    desc "run core specs in fail-fast mode, using the released logstash-core gem"
    task "core-fail-fast" do
      exit(LogStash::RSpec.run(["--fail-fast", LogStash::RSpec.core_specs]))
    end

    desc "run core specs on a single file, using the released logstash-core gem"
    task "core-single-file", [:specfile] => ["setup"] do |t, args|
      exit(LogStash::RSpec.run([Rake::FileList[args.specfile]]))
    end

    desc "run all installed plugins specs, using the released logstash-code gem"
    task "plugins" do
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
      exit(LogStash::RSpec.run(["--order", "rand", test_files]))
    end
  end

  task "install-core" => ["bootstrap", "plugin:install-core", "plugin:install-development-dependencies"]

  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]

  task "install-all" => ["bootstrap", "plugin:install-all", "plugin:install-development-dependencies"]

  task "install-vendor-plugins" => ["bootstrap", "plugin:install-vendor", "plugin:install-development-dependencies"]

  task "install-jar-dependencies-plugins" => ["bootstrap", "plugin:install-jar-dependencies", "plugin:install-development-dependencies"]

  # Setup simplecov to group files per functional modules, like this is easier to spot places with small coverage
  task "setup-simplecov" do
    require "simplecov"
 
    task.reenable
  end

  task "integration" => ["setup"] do
    require "fileutils" 

    source = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    integration_path = File.join(source, "integration_run")
    FileUtils.rm_rf(integration_path)

    exit(LogStash::RSpec.run([Rake::FileList["integration/**/*_spec.rb"]]))
  end

  namespace "integration" do
    task "local" => ["setup"] do
      require "fileutils"

      source = File.expand_path(File.join(File.dirname(__FILE__), ".."))
      integration_path = File.join(source, "integration_run")
      FileUtils.mkdir_p(integration_path)

      puts "[integration_spec] configuring local environment for running test in #{integration_path}, if you want to change this behavior delete the directory."
      exit(LogStash::RSpec.run([Rake::FileList["integration/**/*_spec.rb"]]))
    end
  end
end

task "test" => [ "test:core" ]
