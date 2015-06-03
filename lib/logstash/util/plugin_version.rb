require 'logstash/errors'
require 'rubygems/version'
require 'forwardable'

module LogStash::Util
  class PluginVersion
    extend Forwardable
    include Comparable

    GEM_NAME_PREFIX = 'logstash'

    def_delegators :@version, :to_s
    attr_reader :version

    def initialize(*options)
      if options.size == 1 && options.first.is_a?(Gem::Version)
        @version = options.first
      else
        @version = Gem::Version.new(options.join('.'))
      end
    end

    def self.find_version!(name)
      begin
        specification = Gem::Specification.find_by_name(name)
        new(specification.version)
      rescue Gem::LoadError
        # Rescuing the LoadError and raise a Logstash specific error.
        # Likely we can't find the gem in the current GEM_PATH
        raise LogStash::PluginNoVersionError
      end
    end

    def self.find_plugin_version!(type, name)
      plugin_name = [GEM_NAME_PREFIX, type, name].join('-')
      find_version!(plugin_name)
    end

    def <=>(other)
      version <=> other.version
    end
  end
end
