#!/usr/bin/env ruby

require "rubygems/specification"
require "rubygems/commands/install_command"

gemspec = ARGV.shift || "logstash.gemspec"

spec = Gem::Specification.load(gemspec)
deps = [spec.development_dependencies, spec.runtime_dependencies].flatten

# target for now
target = "vendor/bundle/jruby/1.9/"

deps.each do |dep|
  #cmd = "gem install --install-dir #{target} #{dep.name} -v '#{dep.requirement}'"
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



