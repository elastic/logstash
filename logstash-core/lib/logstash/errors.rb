# encoding: utf-8

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
