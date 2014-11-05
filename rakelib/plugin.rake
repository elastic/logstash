require_relative "default_plugins"
namespace "plugin" do
  task "install",  :name do |task, args|
    name = args[:name]
    puts "[plugin] Installing plugin: #{name}"

    cmd = ['bin/logstash', 'plugin', 'install', name ]
    system(*cmd)
    raise RuntimeError, $!.to_s unless $?.success?

    task.reenable # Allow this task to be run again
  end # task "install"

  task "install-defaults" do
    DEFAULT_PLUGINS.each do |plugin|
      Rake::Task["plugin:install"].invoke(plugin)
    end
  end
end # namespace "plugin"
