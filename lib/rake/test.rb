# encoding: utf-8
require "bootstrap/environment"
require 'pathname'
require "pluginmanager/gemfile"

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

  def point_core_gems_to_local_path
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, 'r+')).load
    find_core_gems.each do |core_gem_name|
      gem = gemfile.find(core_gem_name)
      new_gem = LogStash::Gem.new(core_gem_name, gem.requirements, {:path => "./#{core_gem_name}" })
      gemfile.gemset.update_gem(new_gem)
    end
    gemfile.save
  end

  def find_core_gems
    gemfile = File.readlines(LogStash::Environment::GEMFILE_PATH)
    regexp  = /^gem\s+"(logstash-core[a-z|-]*)"/
    gemfile.map do |line|
      next if line.include?("path")
      match = regexp.match(line)
      next if match.nil?
      match[1]
    end.compact!
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

  class Test

    attr_reader :gemfiles_cache

    def self.setup
      require "bootstrap/environment"
      LogStash::Bundler.setup!({:without => [:build]})
      require "rspec/core/runner"
      require "rspec"
      require 'ci/reporter/rake/rspec_loader'
    end

    def cache_gemfiles
      @gemfiles_cache = GemfileHelpers.new.load
      gemfiles_cache.point_core_gems_to_local_path
      self
    end

    def restore_gemfiles
      gemfiles_cache.restore
    end

    def self.run(specs)
      setup
      ::RSpec::Core::Runner.run(specs)
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

      Rake::FileList[*specs]
    end

  end
end
