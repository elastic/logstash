# encoding: utf-8
module LogStash
  class Error < ::StandardError; end
  class ConfigurationError < Error; end
  class PluginLoadingError < Error; end
  class ShutdownSignal < StandardError; end

  class Bug < Error; end
  class ThisMethodWasRemoved < Bug; end
end
