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

  task "install-defaults" => [ "dependency:bundler" ] do
    ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
    Bundler::CLI.start(LogStash::Environment.bundler_install_command("tools/Gemfile.plugins", LogStash::Environment::BUNDLE_DIR))

    # because --path creates a .bundle/config file and changes bundler path
    # we need to remove this file so it doesn't influence following bundler calls
    FileUtils.rm_rf(::File.join(LogStash::Environment::LOGSTASH_HOME, "tools/.bundle"))
  end
end # namespace "plugin"
