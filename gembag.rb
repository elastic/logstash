#!/usr/bin/env ruby

require "rubygems/specification"
require "rubygems/commands/install_command"

def install_gem(name, requirement, target)
  puts "Fetching and installing gem: #{name} (#{requirement})"

  installer = Gem::Commands::InstallCommand.new
  installer.options[:generate_rdoc] = false
  installer.options[:generate_ri] = false
  installer.options[:version] = requirement
  installer.options[:args] = [name]
  installer.options[:install_dir] = target
  begin
    installer.execute
  rescue Gem::SystemExitException => e
    if e.exit_code != 0
      puts "Installation of #{name} failed"
      raise
    end
  end
end # def install_gem

gemspec = ARGV.shift || "logstash.gemspec"

spec = Gem::Specification.load(gemspec)
deps = [spec.development_dependencies, spec.runtime_dependencies].flatten

# target for now
target = "vendor/bundle/jruby/1.9/"

deps.each do |dep|
  # TODO(sissel): Hack for now
  next if "#{dep}" == "addressable (~> 2.2.6)" 

  begin
    # Check if the gem is available
    # 'gem' returns 'true' if it loaded it, false if already loaded,
    # and raises a Gem::LoadError exception on failure.
    # Skip downloading/installing it if it's already here.
    gem(dep.name, dep.requirement)

    # If we get here, we have the gem.
    puts "Gem found matching: #{dep}"
  rescue Gem::LoadError => e
    # Not installed, continue.
    message = e.to_s

    # Sometimes we failed to load because gembag installs too
    # many things. Like 'shoulda' fails to load because two
    # conflicting versions of 'mocha' were installed.
    # Fundamentally, gembag should build a dependency graph and
    # resolve all version requirements to single nodes to prevent
    # this madness.
    #
    # Possible we can steal bundler's implementation of this,
    # or just use bundler to do it, but only if bundler doesn't
    # bite me in the ass again :)
    case message
      when /Unable to activate/
        puts "Gem found, but funky: #{dep} (#{e})"
      else
        puts "Gem not found: #{dep} (#{e})"
        install_gem(dep.name, dep.requirement, target)
    end # case message
  end # begin / rescue Gem::LoadError
end # deps.each



