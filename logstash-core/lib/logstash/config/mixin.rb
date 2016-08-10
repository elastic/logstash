# encoding: utf-8
require "logstash/namespace"
require "logstash/config/registry"
require "logstash/plugins/registry"
require "logstash/logging"
require "logstash/util/password"
require "logstash/util/safe_uri"
require "logstash/version"
require "logstash/environment"
require "logstash/util/plugin_version"
require "filesize"

require "logstash/config/config_registry"
require "logstash/config/config_validator"

LogStash::Environment.load_locale!

# This module is meant as a mixin to classes wishing to be configurable from
# config files
#
# The idea is that you can do this:
#
# class Foo < LogStash::Config
#   # Add config file settings
#   config "path" => ...
#   config "tag" => ...
#
#   # Add global flags (becomes --foo-bar)
#   flag "bar" => ...
# end
#
# And the config file should let you do:
#
# foo {
#   "path" => ...
#   "tag" => ...
# }
#
module LogStash::Config::Mixin
  attr_accessor :config
  attr_accessor :original_params

  ENV_PLACEHOLDER_REGEX = /\$\{(?<name>\w+)(\:(?<default>[^}]*))?\}/

  # This method is called when someone does 'include LogStash::Config'
  def self.included(base)
    # Add the DSL methods to the 'base' given.
    base.extend(LogStash::Config::Mixin::DSL)
  end

  def config_init(params)
    original_params = params.clone

    @registry  = LogStash::Config::InternalRegistry.new(self, params, @logger)

    @registry.setup do |validator, _params|
      valid, _ = validator.valid_params?(_params)
      if !valid
        raise LogStash::ConfigurationError, I18n.t("logstash.runner.configuration.invalid_plugin_settings")
      end
      valid, errors = validator.valid_values?(_params)
      if !valid
        raise LogStash::ConfigurationError, errors.join('\n')
      end
      validator.coerce_values!(_params)
    end

    # now that we know the parameters are valid, we can obfuscate the original copy
    # of the parameters before storing them as an instance variable
    @registry.secure_params!(original_params)
    
    @original_params = original_params
    @config = params
  end # def config_init

  module DSL
    attr_accessor :flags

    # If name is given, set the name and return it.
    # If no name given (nil), return the current name.
    def config_name(name = nil)
      @config_name = name if !name.nil?
      LogStash::Config::Registry.registry[@config_name] = self
      if self.respond_to?("plugin_type")
        declare_plugin(self.plugin_type, @config_name)
      end
      return @config_name
    end
    alias_method :config_plugin, :config_name

    # Define a new configuration setting
    def config(name, opts={})
      @config ||= Hash.new
      # TODO(sissel): verify 'name' is of type String, Symbol, or Regexp

      name = name.to_s if name.is_a?(Symbol)
      @config[name] = opts  # ok if this is empty

      if name.is_a?(String)
        define_method(name) { instance_variable_get("@#{name}") }
        define_method("#{name}=") { |v| instance_variable_set("@#{name}", v) }
      end
    end # def config

    def default(name, value)
      @defaults ||= {}
      @defaults[name.to_s] = value
    end

    def milestone(*args)

    end

    def get_config
      return @config
    end # def get_config

    def get_default(name)
      return @defaults && @defaults[name]
    end

    def default?(name)
      return @defaults && @defaults.include?(name)
    end

    def options(opts)
      # add any options from this class
      prefix = self.name.split("::").last.downcase
      @flags.each do |flag|
        flagpart = flag[:args].first.gsub(/^--/,"")
        # TODO(sissel): logger things here could help debugging.

        opts.on("--#{prefix}-#{flagpart}", *flag[:args][1..-1], &flag[:block])
      end
    end # def options

    # This is called whenever someone subclasses a class that has this mixin.
    def inherited(subclass)
      # Copy our parent's config to a subclass.
      # This method is invoked whenever someone subclasses us, like:
      # class Foo < Bar ...
      subconfig = Hash.new
      if !@config.nil?
        @config.each do |key, val|
          subconfig[key] = val
        end
      end
      subclass.instance_variable_set("@config", subconfig)
    end # def inherited

  end # module LogStash::Config::DSL
end # module LogStash::Config
