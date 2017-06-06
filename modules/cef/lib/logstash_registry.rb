LogStash::PLUGIN_REGISTRY.add(:modules, "cef", LogStash::Modules::Scaffold.new("cef", File.join(File.dirname(__FILE__), "..", "configuration")))
