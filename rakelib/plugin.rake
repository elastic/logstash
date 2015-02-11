require_relative "default_plugins"

def install_plugins(*args)
  cmd = ["bin/plugin", "install", *args]
  system(*cmd)
  raise RuntimeError, $!.to_s unless $?.success?
end

namespace "plugin" do

  task "install-development-dependencies" do
    puts("[plugin:install-development-dependencies] Installing development dependencies of all installed plugins")
    install_plugins("--development")

    task.reenable # Allow this task to be run again
  end

  task "install",  :name do |task, args|
    name = args[:name]
    puts("[plugin:install] Installing plugin: #{name}")
    install_plugins("--force", name)

    task.reenable # Allow this task to be run again
  end # task "install"

  task "install-defaults" do
    puts("[plugin:install-defaults] Installing default plugins")
    install_plugins("--force", *::DEFAULT_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-test" do
    puts("[plugin:install-test] Installing test plugins")
    install_plugins("--force", *::TEST_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-all" => [ "dependency:octokit" ] do
    puts("[plugin:install-all] Installing all plugins based on all repos in the logstash-plugins github organization")
    install_plugins("--force", *all_plugins)

    task.reenable # Allow this task to be run again
  end
end # namespace "plugin"
