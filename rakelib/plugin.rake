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

    env = {
      "GEM_PATH" => [
        LogStash::Environment.logstash_gem_home,
        LogStash::Environment.plugins_gem_home,
        ::File.join(LogStash::Environment::LOGSTASH_HOME, "build/bootstrap"),
      ].join(":")
    }
    cmd = [LogStash::Environment.ruby_bin, "-S"] + LogStash::Environment.bundler_install_command("tools/Gemfile.plugins", LogStash::Environment::PLUGINS_DIR)
    system(env, *cmd)
    raise RuntimeError, $!.to_s unless $?.success?
  end
end # namespace "plugin"
