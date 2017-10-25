# encoding: utf-8

# Force loading the RubyUtil to ensure that the custom Exception types it sets up are ready at the
# same time as those that are set by this script.
java_import org.logstash.RubyUtil

module LogStash
  class EnvironmentError < Error; end
  class ConfigurationError < Error; end
  class PluginLoadingError < Error; end
  class ShutdownSignal < StandardError; end
  class PluginNoVersionError < Error; end
  class BootstrapCheckError < Error; end

  class Bug < Error; end
  class ThisMethodWasRemoved < Bug; end
  class ConfigLoadingError < Error; end
  class InvalidSourceLoaderSettingError < Error; end
end
