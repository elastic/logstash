require_relative "default_plugins"

def install_plugins(*args)
  system("bin/plugin", "install", *args)
  raise(RuntimeError, $!.to_s) unless $?.success?
end

namespace "plugin" do

  task "install-development-dependencies" do
    puts("[plugin:install-development-dependencies] Installing development dependencies of all installed plugins")
    install_plugins("--development")

    task.reenable # Allow this task to be run again
  end

  task "install", :name do |task, args|
    name = args[:name]
    puts("[plugin:install] Installing plugin: #{name}")
    install_plugins("--force", name)

    task.reenable # Allow this task to be run again
  end # task "install"

  task "install-default" do
    puts("[plugin:install-default] Installing default plugins")
    install_plugins("--force", *::DEFAULT_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-core" do
    puts("[plugin:install-core] Installing core plugins")
    install_plugins("--force", *::CORE_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-all" => [ "dependency:octokit" ] do
    puts("[plugin:install-all] Installing all plugins from https://github.com/logstash-plugins")
    install_plugins("--force", *all_plugins)

    task.reenable # Allow this task to be run again
  end
end # namespace "plugin"
