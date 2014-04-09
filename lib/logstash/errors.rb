# encoding: utf-8
module LogStash
  class Error < ::StandardError; end
  class EnvironmentError < Error; end
  class ConfigurationError < Error; end
  class PluginLoadingError < Error; end
  class ShutdownSignal < StandardError; end

  class Bug < Error; end
  class ThisMethodWasRemoved < Bug; end
end
