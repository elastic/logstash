# encoding: utf-8
require "logstash/namespace"
require "logstash/config/coercers/boolean"
require "logstash/config/coercers/bytes"
require "logstash/config/coercers/codec"
require "logstash/config/coercers/hash"
require "logstash/config/coercers/number"
require "logstash/config/coercers/password"
require "logstash/config/coercers/uri"


module LogStash::Config

  class EnvironmentVariables

    ENV_PLACEHOLDER_REGEX = /\$\{(?<name>\w+)(\:(?<default>[^}]*))?\}/

    # Replace all environment variable references in 'value' param by environment variable value and return updated value
    # Process following patterns : $VAR, ${VAR}, ${VAR:defaultValue}
    def self.replace_env_placeholders(value)
      return value unless value.is_a?(String)

      value.gsub(ENV_PLACEHOLDER_REGEX) do |placeholder|
        # Note: Ruby docs claim[1] Regexp.last_match is thread-local and scoped to
        # the call, so this should be thread-safe.
        #
        # [1] http://ruby-doc.org/core-2.1.1/Regexp.html#method-c-last_match
        name = Regexp.last_match(:name)
        default = Regexp.last_match(:default)

        replacement = ENV.fetch(name, default)
        if replacement.nil?
          raise LogStash::ConfigurationError, "Cannot evaluate `#{placeholder}`. Environment variable `#{name}` is not set and there is no default value given."
        end
        replacement
      end
    end # def replace_env_placeholders
  end

  class InternalRegistry

    attr_reader :parent, :klass, :config, :params, :logger, :validator
    attr_writer :params

    def initialize(parent, params, logger)
      @params = params
      @logger = logger
      @klass  = parent.class
      @parent = parent
      plugin_type = klass.ancestors.find { |a| a.name =~ /::Base$/ }.config_name
      @validator = LogStash::Config::Validation.new(config, plugin_type, config_name, logger)
    end

    def setup(&block)
      warn_deprecated_and_obsolete

      # fetch defaults and environment variables
      initialize_defaults
      resolv_environment_variables 

      # validate and coerce values
      block.call(validator, params)

      # We remove any config options marked as obsolete,
      # no code should be associated to them and their values should not bleed
      # to the plugin context.
      #
      # This need to be done after fetching the options from the parents classed
      remove_obsolete

      # set instance variables like '@foo'  for each config value given.
      set_instance_vars
    end

    def warn_deprecated_and_obsolete
      params.each do |name, value|
        opts = config[name]
        if opts && opts[:deprecated]
          extra = opts[:deprecated].is_a?(String) ? opts[:deprecated] : ""
          extra.gsub!("%PLUGIN%", config_name)
          @logger.warn("You are using a deprecated config setting " +
                       "#{name.inspect} set in #{config_name}. " +
                       "Deprecated settings will continue to work, " +
                       "but are scheduled for removal from logstash " +
                       "in the future. #{extra} If you have any questions " +
                       "about this, please visit the #logstash channel " +
                       "on freenode irc.", :name => name, :plugin => parent)
        end
        if opts && opts[:obsolete]
          extra = opts[:obsolete].is_a?(String) ? opts[:obsolete] : ""
          extra.gsub!("%PLUGIN%", config_name)
          raise LogStash::ConfigurationError,
            I18n.t("logstash.runner.configuration.obsolete", :name => name, :plugin => config_name, :extra => extra)
        end
      end
    end

    # We remove any config options marked as obsolete,
    # no code should be associated to them and their values should not bleed
    # to the plugin context.
    #
    # This need to be done after fetching the options from the parents classed
    def remove_obsolete
      params.reject! do |name, value|
        opts = config[name]
        opts.include?(:obsolete)
      end
    end

    def set_instance_vars
      params.each do |key, value|
        next if key[0,  1] == "@"
        # Set this key as an instance variable only if it doesn't start with an '@'
        @logger.debug("config #{self.class.name}/@#{key} = #{value.inspect}")
        parent.instance_variable_set("@#{key}", value)
      end
    end

    # now that we know the parameters are valid, we can obfuscate the original copy
    # of the parameters before storing them as an instance variable
    def secure_params!(params)
      params.each do |key, value|
        klass = nil
        case config[key][:validate]
        when :uri
          klass = LogStash::Config::TypeCoercers::Uri
        when :password
          klass = LogStash::Config::TypeCoercers::Password
        end

        next unless klass

        if config[key][:list]
          params[key] = params[key].map { |_value| klass.coerce(_value) }
        else
          params[key] = klass.coerce(value)
        end
      end
    end

    def initialize_defaults
      config.each do |name, opts|
        next if params.include?(name.to_s)
        if opts.include?(:default) && (name.is_a?(Symbol) || name.is_a?(String))
          case opts[:default]
          when FalseClass, TrueClass, NilClass, Numeric
            params[name.to_s] = opts[:default]
          else
            params[name.to_s] = opts[:default].clone
          end
        end
        # Allow plugins to override default values of config settings
        if klass.default?(name)
          params[name.to_s] = klass.get_default(name)
        end
      end
    end

    def resolv_environment_variables
      params.each do |name, value|
        if (value.is_a?(Hash))
          value.each do |valueHashKey, valueHashValue|
            value[valueHashKey.to_s] = EnvironmentVariables.replace_env_placeholders(valueHashValue)
          end
        else
          if (value.is_a?(Array))
            value.each_index do |valueArrayIndex|
              value[valueArrayIndex] = EnvironmentVariables.replace_env_placeholders(value[valueArrayIndex])
            end
          else
            params[name.to_s] = EnvironmentVariables.replace_env_placeholders(value)
          end
        end
      end
    end

    def config
      @config ||= klass.get_config
    end

    def config_name
      @config_name ||= klass.config_name
    end

  end
end
