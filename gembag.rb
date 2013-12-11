#!/usr/bin/env ruby

require "rbconfig"

rubyabi = RbConfig::CONFIG["ruby_version"]
target = "#{Dir.pwd}/vendor/bundle"
gemdir = "#{target}/#{RUBY_ENGINE}/#{rubyabi}/"
ENV["GEM_HOME"] = gemdir
ENV["GEM_PATH"] = ""

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
 
  # ruby 2.0.0 / rubygems 2.x; disable documentation generation
  installer.options[:document] = []
  begin
    installer.execute
  rescue Gem::SystemExitException => e
    if e.exit_code != 0
      puts "Installation of #{name} failed"
      raise
    end
  end
end # def install_gem

# Ensure bundler is available.
begin
  gem("bundler", ">=1.3.5")
rescue Gem::LoadError => e
  install_gem("bundler", ">= 1.3.5", ENV["GEM_HOME"])
end

require "bundler/cli"

# Monkeypatch bundler to write a .lock file specific to the version of ruby.
# This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
module Bundler
  module SharedHelpers
    def default_lockfile
      ruby = "#{RUBY_ENGINE}-#{RbConfig::CONFIG["ruby_version"]}"
      return Pathname.new("#{default_gemfile}.#{ruby}.lock")
    end
  end
end

if RUBY_ENGINE == "rbx"
  begin
    gem("rubysl")
  rescue Gem::LoadError => e
    install_gem("rubysl", ">= 0", ENV["GEM_HOME"])
  end
end

Bundler::CLI.start(["install", "--gemfile=tools/Gemfile", "--path", target, "--clean"])
