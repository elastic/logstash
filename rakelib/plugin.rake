require_relative "default_plugins"

namespace "plugin" do

  def install_plugins(*args)
    system("bin/plugin", "install", *args)
    raise(RuntimeError, $!.to_s) unless $?.success?
  end

  task "install-development-dependencies" do
    puts("[plugin:install-development-dependencies] Installing development dependencies of all installed plugins")
    install_plugins("--development")

    task.reenable # Allow this task to be run again
  end

  task "install", :name do |task, args|
    name = args[:name]
    puts("[plugin:install] Installing plugin: #{name}")
    install_plugins("--no-verify", name)

    task.reenable # Allow this task to be run again
  end # task "install"

  task "install-default" do
    puts("[plugin:install-default] Installing default plugins")
    install_plugins("--no-verify", *LogStash::RakeLib::DEFAULT_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-core" do
    puts("[plugin:install-core] Installing core plugins")
    install_plugins("--no-verify", *LogStash::RakeLib::CORE_SPECS_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-jar-dependencies" do
    puts("[plugin:install-jar-dependencies] Installing jar_dependencies plugins for testing")
    install_plugins("--no-verify", *LogStash::RakeLib::TEST_JAR_DEPENDENCIES_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-vendor" do
    puts("[plugin:install-jar-dependencies] Installing vendor plugins for testing")
    install_plugins("--no-verify", *LogStash::RakeLib::TEST_VENDOR_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-all" do
    puts("[plugin:install-all] Installing all plugins from https://github.com/logstash-plugins")
    install_plugins("--no-verify", *LogStash::RakeLib.fetch_all_plugins)

    task.reenable # Allow this task to be run again
  end

  task "clean-logstash-core-gem" do
    Dir["logstash-core*.gem"].each do |gem|
      rm(gem)
    end

    task.reenable # Allow this task to be run again
  end

  task "build-logstash-core-gem" => [ "clean-logstash-core-gem" ] do
    puts("[plugin:build-logstash-core-gem] Building logstash-core.gemspec")

    system("gem build logstash-core.gemspec")

    task.reenable # Allow this task to be run again
  end

  task "install-local-logstash-core-gem" => [ "build-logstash-core-gem" ] do
    gems = Dir["logstash-core*.gem"]
    abort("ERROR: logstash-core gem not found") if gems.size != 1
    puts("[plugin:install-local-logstash-core-gem] Installing #{gems.first}")
    install_plugins("--no-verify", gems.first)

    task.reenable # Allow this task to be run again
  end

end # namespace "plugin"
