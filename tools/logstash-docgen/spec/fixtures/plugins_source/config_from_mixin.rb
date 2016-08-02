# encoding: utf-8

module ConfigFromMixin
  # Config mixing description
  config :config_mixin, :type => :string, :default => "mixin config", :required => true

  # A deprecated config option
  config :config_mixin_deprecated, :type => :string, :deprecated => true
end
