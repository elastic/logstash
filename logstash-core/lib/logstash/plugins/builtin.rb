module ::LogStash::Plugins::Builtin
  require 'logstash/plugins/builtin/internal/input'
  require 'logstash/plugins/builtin/internal/output'

  LogStash::PLUGIN_REGISTRY.add(:input, "internal", LogStash::Plugins::Builtin::Internal::Input)
  LogStash::PLUGIN_REGISTRY.add(:output, "internal", LogStash::Plugins::Builtin::Internal::Output)
end