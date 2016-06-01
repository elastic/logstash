require_relative "default_plugins"
require 'rubygems'

namespace "plugin" do

  def install_plugins(*args)
    system("bin/logstash-plugin", "install", *args)
    raise(RuntimeError, $!.to_s) unless $?.success?
  end

  task "install-development-dependencies" do
    puts("[plugin:install-development-dependencies] Installing development dependencies of all installed plugins")
    install_plugins("--development",  "--preserve")

    task.reenable # Allow this task to be run again
  end

  task "install", :name do |task, args|
    name = args[:name]
    puts("[plugin:install] Installing plugin: #{name}")
    install_plugins("--no-verify", "--preserve", name)

    task.reenable # Allow this task to be run again
  end # task "install"

  task "install-default" do
    puts("[plugin:install-default] Installing default plugins")
    install_plugins("--no-verify", "--preserve", *LogStash::RakeLib::DEFAULT_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-core" do
    puts("[plugin:install-core] Installing core plugins")
    install_plugins("--no-verify", "--preserve", *LogStash::RakeLib::CORE_SPECS_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-jar-dependencies" do
    puts("[plugin:install-jar-dependencies] Installing jar_dependencies plugins for testing")
    install_plugins("--no-verify", "--preserve", *LogStash::RakeLib::TEST_JAR_DEPENDENCIES_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-vendor" do
    puts("[plugin:install-jar-dependencies] Installing vendor plugins for testing")
    install_plugins("--no-verify", "--preserve", *LogStash::RakeLib::TEST_VENDOR_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install-all" do
    puts("[plugin:install-all] Installing all plugins from https://github.com/logstash-plugins")
    p = *LogStash::RakeLib.fetch_all_plugins
    # Install plugin one by one, ignoring plugins that have issues. Otherwise, one bad plugin will
    # blow up the entire install process.
    # TODO Push this downstream to #install_plugins
    p.each do |plugin|
      begin
        install_plugins("--no-verify", "--preserve", plugin)
      rescue
        puts "Unable to install #{plugin}. Skipping"
        next
      end
    end

    task.reenable # Allow this task to be run again
  end

  task "clean-local-core-gem", [:name, :path] do |task, args|
    name = args[:name]
    path = args[:path]

    Dir[File.join(path, "#{name}*.gem")].each do |gem|
      puts("[plugin:clean-local-core-gem] Cleaning #{gem}")
      rm(gem)
    end

    task.reenable # Allow this task to be run again
  end

  task "build-local-core-gem", [:name, :path] => ["build/gems"]  do |task, args|
    name = args[:name]
    path = args[:path]

    Rake::Task["plugin:clean-local-core-gem"].invoke(name, path)

    puts("[plugin:build-local-core-gem] Building #{File.join(path, name)}.gemspec")

    gem_path = nil
    Dir.chdir(path) do
      spec = Gem::Specification.load("#{name}.gemspec")
      gem_path = Gem::Package.build(spec)
    end
    FileUtils.cp(File.join(path, gem_path), "build/gems/")

    task.reenable # Allow this task to be run again
  end

  task "install-local-core-gem", [:name, :path] do |task, args|
    name = args[:name]
    path = args[:path]

    Rake::Task["plugin:build-local-core-gem"].invoke(name, path)

    gems = Dir[File.join(path, "#{name}*.gem")]
    abort("ERROR: #{name} gem not found in #{path}") if gems.size != 1
    puts("[plugin:install-local-core-gem] Installing #{gems.first}")
    install_plugins("--no-verify", gems.first)

    task.reenable # Allow this task to be run again
  end

end # namespace "plugin"
