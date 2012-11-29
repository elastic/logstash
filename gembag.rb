#!/usr/bin/env ruby

require "rubygems/specification"
require "rubygems/commands/install_command"

gemspec = ARGV.shift || "logstash.gemspec"

spec = Gem::Specification.load(gemspec)
deps = [spec.development_dependencies, spec.runtime_dependencies].flatten

# target for now
target = "vendor/bundle/jruby/1.9/"

deps.each do |dep|
  begin
    # Check if the gem is available
    # 'gem' returns true if successful
    # Skip downloading/installing it if it's already here.
    if gem(dep.name, dep.requirement)
      puts "Gem found matching: #{dep.name} #{dep.requirement}"
      next
    end
  rescue Gem::LoadError
    # Not installed, continue.
  end

  puts "Fetching and installing gem: #{dep.name} #{dep.requirement}"

  installer = Gem::Commands::InstallCommand.new
  installer.options[:generate_rdoc] = false
  installer.options[:generate_ri] = false
  installer.options[:version] = dep.requirement
  installer.options[:args] = [dep.name]
  installer.options[:install_dir] = target
  begin
    installer.execute
  rescue Gem::SystemExitException => e
    if e.exit_code != 0
      puts "Installation of #{dep.to_s} failed"
      raise
    end
  end
end



