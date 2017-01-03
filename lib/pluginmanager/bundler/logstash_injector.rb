# encoding: utf-8
require "bootstrap/environment"
require "bundler"
require "bundler/definition"
require "bundler/dependency"
require "bundler/dsl"
require "bundler/injector"
require "pluginmanager/gemfile"


# This class cannot be in the logstash namespace, because of the way the DSL
# class interact with the other libraries
module Bundler
  class LogstashInjector < ::Bundler::Injector
    def self.inject!(new_deps, options = { :gemfile => LogStash::Environment::GEMFILE, :lockfile => LogStash::Environment::LOCKFILE })
      gemfile = options.delete(:gemfile)
      lockfile = options.delete(:lockfile)

      bundler_format = new_deps.plugins.collect(&method(:dependency))
      dependencies = new_deps.dependencies.collect(&method(:dependency))

      injector = new(bundler_format)
      injector.inject(gemfile, lockfile, dependencies)
    end

    def self.dependency(plugin)
      ::Bundler::Dependency.new(plugin.name, "=#{plugin.version}")
    end

    # This class is pretty similar to what bundler's injector class is doing
    # but we only accept a local resolution of the dependencies instead of calling rubygems.
    # so we removed `definition.resolve_remotely!`
    #
    # And managing the gemfile is down by using our own Gemfile parser, this allow us to
    # make it work with gems that are already defined in the gemfile.
    def inject(gemfile_path, lockfile_path, dependencies)
      if Bundler.settings[:frozen]
        # ensure the lock and Gemfile are synced
        Bundler.definition.ensure_equivalent_gemfile_and_lockfile(true)
        # temporarily remove frozen while we inject
        frozen = Bundler.settings.delete(:frozen)
      end

      builder = Dsl.new
      gemfile = LogStash::Gemfile.new(File.new(gemfile_path, "r+")).load

      begin
        @new_deps.each do |dependency|
          gemfile.update(dependency.name, dependency.requirement)
        end

        # If the dependency is defined in the gemfile, lets try to update the version with the one we have
        # with the pack.
        dependencies.each do |dependency|
          if gemfile.defined_in_gemfile?(dependency.name)
            gemfile.update(dependency.name, dependency.requirement)
          end
        end

        builder.eval_gemfile("bundler file", gemfile.generate())
        definition = builder.to_definition(lockfile_path, {})
        definition.lock(lockfile_path)
        gemfile.save
      rescue => e
        # the error should be handled elsewhere but we need to get the original file if we dont
        # do this logstash will be in an inconsistent state
        gemfile.restore!
        raise e
      end
    ensure
      Bundler.settings[:frozen] = "1" if frozen
    end
  end
end
