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
    gem_path = ENV['GEM_PATH']
    gem_home = ENV['GEM_HOME']
    env = {
      "GEM_PATH" => [
        ENV['GEM_PATH'],
        ::File.join(LogStash::Environment::LOGSTASH_HOME, 'build/bootstrap'),
        ::File.join(LogStash::Environment::LOGSTASH_HOME, 'vendor/bundle/jruby/1.9'),
        ::File.join(LogStash::Environment::LOGSTASH_HOME, 'vendor/jruby/lib/ruby/gems/shared')
      ].join(":"),
      "GEM_HOME" => ::File.join(LogStash::Environment::LOGSTASH_HOME, "vendor/plugins/jruby/1.9"),
      "BUNDLE_GEMFILE" => "tools/Gemfile.plugins"
    }
    if ENV['USE_RUBY'] != '1'
      jruby = File.join("vendor", "jruby", "bin", "jruby")
      bundle = File.join("build", "bootstrap", "bin", "bundle")
      system(env, jruby, "-S", bundle, "install")
    else
      system(env, "bundle", "install")
    end
    ENV['GEM_PATH'] = gem_path
    ENV['GEM_HOME'] = gem_home
  end
end # namespace "plugin"
