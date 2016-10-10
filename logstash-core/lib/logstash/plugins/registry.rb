# encoding: utf-8
require 'singleton'
require "rubygems/package"
require "logstash/util/loggable"

module LogStash
  class Registry
    include LogStash::Util::Loggable

    ##
    # Placeholder class for registered plugins
    ##
    class Plugin
      attr_reader :type, :name

      def initialize(type, name)
        @type  = type
        @name  = name
      end

      def path
        "logstash/#{type}s/#{name}"
      end

      def cannonic_gem_name
        "logstash-#{type}-#{name}"
      end

      def installed?
        find_plugin_spec(cannonic_gem_name).any?
      end

      private

      def find_plugin_spec(name)
        specs = ::Gem::Specification.find_all_by_name(name)
        specs.select{|spec| logstash_plugin_spec?(spec)}
      end

      def logstash_plugin_spec?(spec)
        spec.metadata && spec.metadata["logstash_plugin"] == "true"
      end

    end

    include Singleton

    def initialize
      @registry = {}
      @logger = self.logger
    end

    def lookup(type, plugin_name, &block)

      plugin = Plugin.new(type, plugin_name)

      if plugin.installed?
        return @registry[plugin.path] if registered?(plugin.path)
        require plugin.path
        klass = @registry[plugin.path]
        if block_given? # if provided pass a block to do validation
          raise LoadError unless block.call(klass, plugin_name)
        end
        return klass
      else
        # The plugin was defined directly in the code, so there is no need to use the
        # require way of loading classes
        return @registry[plugin.path] if registered?(plugin.path)
        raise LoadError
      end
    rescue => e
      @logger.warn("Problems loading a plugin with", :type => type, :name => plugin, :path => plugin.path,
                   :error_message => e.message, :error_class => e.class, :error_backtrace => e.backtrace)
      raise LoadError, "Problems loading the requested plugin named #{plugin_name} of type #{type}. Error: #{e.class} #{e.message}"
    end

    def register(path, klass)
      @registry[path] = klass
    end

    def registered?(path)
      @registry.has_key?(path)
    end

  end
end
