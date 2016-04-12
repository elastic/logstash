# encoding: utf-8
require_relative "../bootstrap/environment"
require 'pathname'
require_relative "../pluginmanager/gemfile"

class GemfileHelpers

  attr_accessor :gemfile, :gemfile_lock, :default_lockfile

  def load
    @gemfile      = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, 'r+')).load
    @gemfile_lock = File.read(default_lockfile)
    self
  end

  def restore
    gemfile.save
    File.write(default_lockfile, gemfile_lock)
  end

  def point_to_local_core_gems
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, 'r+')).load
    find_core_gems.each do |core_gem_name|
        update_gem(gemfile, core_gem_name, {:path => "./#{core_gem_name}" })
    end
    gemfile.save
  end

  def point_to_released_core_gems
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, 'r+')).load
    find_core_gems.each do |core_gem_name|
      update_gem(gemfile, core_gem_name, {})
    end
    gemfile.save
  end

  def find_core_gems
    gemfile = File.readlines(LogStash::Environment::GEMFILE_PATH)
    regexp  = /^gem\s+"(logstash-core[a-z|-]*)"/
    gemfile.map do |line|
      match = regexp.match(line)
      next if match.nil?
      match[1]
    end.compact!
  end

  def update_gem(gemfile, core_gem_name, options)
    gem = gemfile.find(core_gem_name)
    new_gem = LogStash::Gem.new(core_gem_name, gem.requirements, {:path => "./#{core_gem_name}" })
    gemfile.gemset.update_gem(new_gem)
  end

  private

  def default_lockfile
    ruby = "#{LogStash::Environment.ruby_engine}-#{LogStash::Environment.ruby_abi_version}"
    Pathname.new("Gemfile.#{ruby}.lock")
  end
end

module LogStash
  module BundlerHelpers
    def self.update
      puts("Invoking bundler update...")
      output, exception = LogStash::Bundler.invoke!
      puts(output)
      raise(exception) if exception
    end
  end
end


module LogStash

  class RSpec

    attr_reader :gemfiles_cache

    def self.setup
      # Need to be run here as because if run aftewarse (after the bundler.setup task) then the report got wrong
      # numbers and misses files. There is an issue with our setup! method as this does not happen with the regular
      # bundler.setup used in regular bundler flows.
      self.setup_coverage_report if ENV['COVERAGE']
      require "bootstrap/environment"
      LogStash::Bundler.setup!({:without => [:build]})
      require "rspec/core/runner"
      require "rspec"
      require 'ci/reporter/rake/rspec_loader'
    end

    def self.setup_coverage_report
      SimpleCov.start do
        # Skip non core related directories and files.
        ["vendor/", "spec/", "bootstrap/rspec", "Gemfile", "gemspec"].each do |pattern|
          add_filter pattern
        end

        add_group "bootstrap", "bootstrap/" # This module is used during bootstraping of LS
        add_group "plugin manager", "pluginmanager/" # Code related to the plugin manager
        add_group "core" do |src_file| # The LS core codebase
          /logstash\/\w+.rb/.match(src_file.filename)
        end
        add_group "core-util", "logstash/util" # Set of LS utils module
        add_group "core-config", "logstash/config" # LS Configuration modules
        add_group "core-patches", "logstash/patches" # Patches used to overcome known issues in dependencies.
        # LS Core plugins code base.
        add_group "core-plugins", [ "logstash/codecs", "logstash/filters", "logstash/outputs", "logstash/inputs" ]
      end
    end

    def cache_gemfiles
      @gemfiles_cache = GemfileHelpers.new.load
      self
    end

    def point_to_released_core_gems
      gemfiles_cache.point_to_released_core_gems
    end

    def point_to_local_core_gems
      gemfiles_cache.point_to_local_core_gems
    end

    def restore_gemfiles
      gemfiles_cache.restore
    end

    def run(specs)
      self.class.setup
      ::RSpec::Core::Runner.run(specs)
    end

    def run_with_local_core_gems(specs)
      cache_gemfiles
      point_to_local_core_gems
      LogStash::BundlerHelpers.update
      exit_code = run(specs)
    rescue
      exit_code = 1 # Something when wrong
    ensure
      restore_gemfiles
      exit_code
    end

    def self.run(specs)
      self.new.run(specs)
    end

    def self.run_with_local_core_gems(specs)
      rspec = self.new
      rspec.run_with_local_core_gems(specs)
    end

    def self.core_specs
      # note that regardless if which logstash-core-event-* gem is live, we will always run the
      # logstash-core-event specs since currently this is the most complete Event and Timestamp specs
      # which actually defines the Event contract and should pass regardless of the actuall underlying
      # implementation.
      specs = ["spec/**/*_spec.rb", "logstash-core/spec/**/*_spec.rb", "logstash-core-event/spec/**/*_spec.rb"]

      # figure if the logstash-core-event-java gem is loaded and if so add its specific specs in the core specs to run
      begin
        require "logstash-core-event-java/version"
        specs << "logstash-core-event-java/spec/**/*_spec.rb"
      rescue LoadError
        # logstash-core-event-java gem is not live, ignore and skip specs
      end
      require "rake"
      ::Rake::FileList[*specs]
    end

  end
end
