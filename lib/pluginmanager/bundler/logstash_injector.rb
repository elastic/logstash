# encoding: utf-8
require "bootstrap/environment"
require "bundler"
require "bundler/definition"
require "bundler/dependency"
require "bundler/dsl"
require "bundler/injector"

# This class cannot be in the logstash namespace, because of the way the DSL
# class interact with the other libraries
module Bundler
  class LogstashInjector < ::Bundler::Injector
    def self.inject!(new_deps, options = { :gemfile => LogStash::Environment::GEMFILE, :lockfile => LogStash::Environment::LOCKFILE })
      gemfile = options.delete(:gemfile)
      lockfile = options.delete(:lockfile)

      bundler_format = Array(new_deps).collect { |plugin|  ::Bundler::Dependency.new(plugin.name, "=#{plugin.version}")}

      injector = new(bundler_format)
      injector.inject(gemfile, lockfile)
    end


    # This class is pretty similar to what bundler's injector class is doing
    # but we only accept a local resolution of the dependencies instead of calling rubygems.
    # so we removed `definition.resolve_remotely!`
    def inject(gemfile_path, lockfile_path)
      if Bundler.settings[:frozen]
        # ensure the lock and Gemfile are synced
        Bundler.definition.ensure_equivalent_gemfile_and_lockfile(true)
        # temporarily remove frozen while we inject
        frozen = Bundler.settings.delete(:frozen)
      end

      builder = Dsl.new
      builder.eval_gemfile(gemfile_path)

      @new_deps -= builder.dependencies

      builder.eval_gemfile("injected gems", new_gem_lines) if @new_deps.any?
      definition = builder.to_definition(lockfile_path, {})
      append_to(gemfile_path) if @new_deps.any?
      definition.lock(lockfile_path)

      return @new_deps
    ensure
      Bundler.settings[:frozen] = "1" if frozen
    end
  end
end
