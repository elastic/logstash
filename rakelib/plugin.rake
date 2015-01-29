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
    Rake::Task["vendor:bundle"].invoke("Gemfile")
  end

  task "install-test" do
    Rake::Task["vendor:bundle"].invoke("tools/Gemfile.plugins.test")
  end

  task "install-all" => [ "dependency:octokit" ] do
    Rake::Task["vendor:bundle"].invoke("tools/Gemfile.plugins.all")
  end

end # namespace "plugin"
