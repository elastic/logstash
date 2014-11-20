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
      "GEM_PATH" => "#{ENV['GEM_PATH']}:vendor/bundle/jruby/1.9",
      "GEM_HOME" => "vendor/plugins/jruby/1.9"
    }
    system(env, "bundle install")
  end
end # namespace "plugin"
