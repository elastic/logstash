require "rubygems/specification"
require "rubygems/commands/install_command"

namespace "gem" do
  task "require",  :name, :requirement do |task, args|
    name, requirement = args[:name], args[:requirement]

    require "bootstrap/environment"
    ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
    Gem.use_paths(LogStash::Environment.logstash_gem_home)

    begin
      gem name, requirement
    rescue Gem::LoadError => e
      puts "Installing #{name} #{requirement} because the build process needs it."
      Rake::Task["gem:install"].invoke(name, requirement, LogStash::Environment.logstash_gem_home)
    end
    task.reenable # Allow this task to be run again
  end

  task "install", [:name, :requirement, :target] =>  ["build/bootstrap"] do |task, args|
    name, requirement, target = args[:name], args[:requirement], args[:target]

    ENV["GEM_HOME"] = ENV["GEM_PATH"] = target
    Gem.use_paths(target)

    puts "[bootstrap] Fetching and installing gem: #{name} (#{requirement})"

    installer = Gem::Commands::InstallCommand.new
    installer.options[:generate_rdoc] = false
    installer.options[:generate_ri] = false
    installer.options[:version] = requirement
    installer.options[:args] = [name]
    installer.options[:install_dir] = target

    # ruby 2.0.0 / rubygems 2.x; disable documentation generation
    installer.options[:document] = []
    begin
      installer.execute
    rescue Gem::LoadError => e
    # For some weird reason the rescue from the 'require' task is being brought down here
    # We don't know why placing this solves it, but it does.
    rescue Gem::SystemExitException => e
      if e.exit_code != 0
        puts "Installation of #{name} failed"
        raise
      end
    end

    task.reenable # Allow this task to be run again
  end # task "install"
end # namespace "gem"
