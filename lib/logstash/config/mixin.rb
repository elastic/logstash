
require "logstash/namespace"
require "logstash/config/registry"
require "logstash/logging"

# This module is meant as a mixin to classes wishing to be configurable from
# config files
#
# The idea is that you can do this:
#
# class Foo < LogStash::Config
#   config "path" => ...
#   config "tag" => ...
# end
#
# And the config file should let you do:
#
# foo {
#   "path" => ...
#   "tag" => ...
# }
#
# TODO(sissel): This is not yet fully designed.
module LogStash::Config::Mixin
  attr_accessor :config

  # This method is called when someone does 'include LogStash::Config'
  def self.included(base)
    #puts "Configurable class #{base.name}"
    #
    # Add the DSL methods to the 'base' given.
    base.extend(LogStash::Config::Mixin::DSL)
  end

  def config_init(params)
    # Validation will modify the values inside params if necessary.
    # For example: converting a string to a number, etc.
    if !self.class.validate(params)
      @logger.error "Config validation failed."
      exit 1
    end

    params.each do |key, value|
      @logger.info("config #{self.class.name}/@#{key} = #{value.inspect}")

      # set @foo
      #ivar = "@#{key}"
      self.instance_variable_set("@#{key}", value)
    end

    @config = params
  end # def config_init

  module DSL

    # If name is given, set the name and return it.
    # If no name given (nil), return the current name.
    def config_name(name=nil)
      @config_name = name if !name.nil?
      LogStash::Config::Registry.registry[name] = self
      return @config_name
    end

    # If config is given, add this config.
    # If no config given (nil), return the current config hash
    def config(cfg=nil)
      # cfg should be hash with one entry of { "key" => "val" }
      @config ||= Hash.new
      key, value = cfg.to_a.first
      key = key.to_s if key.is_a?(Symbol)
      @config[key] = value
      return @config
    end # def config

    # This is called whenever someone subclasses a class that has this mixin.
    def inherited(subclass)
      # Copy our parent's config to a subclass.
      # This method is invoked whenever someone subclasses us, like:
      # class Foo < Bar ...
      subconfig = Hash.new
      if !@config.nil?
        @config.each do |key, val|
          puts "#{self}: Sharing config '#{key}' with subclass #{subclass}"
          subconfig[key] = val
        end
      end
      subclass.instance_variable_set("@config", subconfig)
    end # def inherited

    def validate(params)
      @plugin_name = [ancestors[1].config_name, config_name].join("/")
      @logger = LogStash::Logger.new(STDERR)
      is_valid = true

      is_valid &&= validate_check_invalid_parameter_names(params)
      is_valid &&= validate_check_parameter_values(params)

      return is_valid
    end # def validate

    def validate_check_invalid_parameter_names(params)
      invalid_params = params.keys
      # Filter out parametrs that match regexp keys.
      # These are defined in plugins like this:
      #   config /foo.*/ => ... 
      @config.each_key do |config_key|
        if config_key.is_a?(Regexp)
          invalid_params.reject! { |k| k =~ config_key }
        elsif config_key.is_a?(String)
          invalid_params.reject! { |k| k == config_key }
        end
      end

      if invalid_params.size > 0
        invalid_params.each do |name|
          @logger.error("Unknown setting '#{name}' for #{@plugin_name}")
        end
        return false
      end # if invalid_params.size > 0
      return true
    end # def validate_check_invalid_parameter_names

    def validate_check_parameter_values(params)
      # Filter out parametrs that match regexp keys.
      # These are defined in plugins like this:
      #   config /foo.*/ => ... 
      is_valid = true

      params.each do |key, value|
        @config.find do |config_key, config_val|
          if (config_key.is_a?(Regexp) && key =~ config_key) \
             || (config_key.is_a?(String) && key == config_key)
            success, result = validate_value(value, config_val)
            if success 
              params[key] = result if !result.nil?
            else
              @logger.error("Failed config #{@plugin_name}/#{key}: #{result} (#{value.inspect})")
            end

            #puts "Result: #{key} / #{result.inspect} / #{success}"
            is_valid &&= success
          end
        end # config.each
      end # params.each

      return is_valid
    end # def validate_check_parameter_values

    def validator_find(key)
      @config.each do |config_key, config_val|
        if (config_key.is_a?(Regexp) && key =~ config_key) \
           || (config_key.is_a?(String) && key == config_key)
          return config_val
        end
      end # @config.each
      return nil
    end

    def validate_value(value, validator)
      # Validator comes from the 'config' pieces of plugins.
      # They look like this
      #   config :mykey => lambda do |value| ... end
      # (see LogStash::Inputs::File for example)
      result = nil

      if validator.nil?
        return true
      elsif validator.is_a?(Proc)
        return validator.call(value)
      elsif validator.is_a?(Array)
        if value.size > 1
          return false, "Expected one of #{validator.inspect}, got #{value.inspect}"
        end

        if !validator.include?(value.first)
          return false, "Expected one of #{validator.inspect}, got #{value.inspect}"
        end
        result = value.first
      elsif validator.is_a?(Symbol)
        # TODO(sissel): Factor this out into a coersion method?
        # TODO(sissel): Document this stuff.
        case validator
          when :hash
            if value.size % 2 == 1
              return false, "This field must contain an even number of items, got #{value.size}"
            end
            # Use Hash[] (works in 1.8.7, anyway) to coerce into a hash.
            p "HASH HASH HASH"
            p "HASH HASH HASH"
            p "HASH HASH HASH"
            p value
            result = Hash[*value]
          when :string
            if value.size > 1 # only one value wanted
              return false, "Expected string, got #{value.inspect}"
            end
            result = value.first
          when :number
            if value.size > 1 # only one value wanted
              return false, "Expected number, got #{value.inspect}"
            end
            if value != value.to_i.to_s # Try convert to number
              return false, "Expected number, got #{value.inspect}"
            end
            result = value.first.to_i
          when :boolean
            if value.size > 1 # only one value wanted
              return false, "Expected boolean, got #{value.inspect}"
            end

            if value.first !~ /^(true|false)$/
              return false, "Expected boolean 'true' or 'false', got #{value.inspect}"
            end

            result = (value.first == "true")
        end # case validator
      else
        return false, "Unknown validator #{validator.class}"
      end

      # Return the validator for later use, like with type coercion.
      return true, result
    end # def validate_value
  end # module LogStash::Config::DSL
end # module LogStash::Config
