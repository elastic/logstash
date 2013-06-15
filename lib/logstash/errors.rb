module LogStash
  class Error < ::StandardError; end
  class ConfigurationError < Error; end
  class PluginLoadingError < Error; end
end
