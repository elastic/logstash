# encoding: utf-8
require "logstash/namespace"

require_relative "validators/parameter_validator"
require_relative "validators/type/array"
require_relative "validators/type/boolean"
require_relative "validators/type/bytes"
require_relative "validators/type/codec"
require_relative "validators/type/hash"
require_relative "validators/type/ipaddr"
require_relative "validators/type/number"
require_relative "validators/type/path"
require_relative "validators/type/string"
require_relative "validators/type/uri"
require_relative "validators/type/password"

require_relative "coercers/null"
require_relative "coercers/array"
require_relative "coercers/boolean"
require_relative "coercers/bytes"
require_relative "coercers/codec"
require_relative "coercers/hash"
require_relative "coercers/number"
require_relative "coercers/password"
require_relative "coercers/uri"


module LogStash::Config

  class ValidatorFactory

    def self.fetch_validator(type)
      fetch_object(TypeValidators, type)
    end

    def self.fetch_coercer(type)
      coercer = fetch_object(TypeCoercers, type) rescue nil
      coercer.nil? ? TypeCoercers::NullCoercer : coercer
    end

    private

    def self.fetch_object(type_class, type)
      begin
        klass = constantize(type)
        if type_class.const_defined?(klass)
           type_class.const_get(klass)
        end
      rescue
        raise NameError.new("#{type_class} of type #{type} is not defined")
      end
    end

    def self.constantize(type)
      type.to_s.capitalize
    end
  end

  class Validation

    attr_reader :config, :plugin_type, :plugin_name, :logger

    def initialize(config, plugin_type, plugin_name, logger=nil)
      @config = config
      @plugin_type = plugin_type
      @plugin_name = plugin_name
      @errors      = []
      @logger      = logger || Cabin::Channel.get(LogStash)
    end

    def valid_params?(params={})
      params_valid, params_errors  = true, []

      [ :validate_attribute_names, :validate_required_params ].each do |validator|

        valid, errors  = self.send(validator, params)
        params_valid  &= valid
        params_errors += errors
      end
      return params_valid, params_errors
    end

    def valid_values?(params={})
      errors = []
      params.each do |key, value|
        validate_with = config[key][:validate]
        next unless validate_with
        validator     = fetch_validator(validate_with, params)
        if config[key][:list]
          list = Array(value)
          list.each do |v|
            errors << validator.errors if !validator.valid?(v)
          end
        else
          errors << validator.errors if !validator.valid?(value)
        end
      end
      [errors.empty?, errors.flatten]
    end

    def coerce_values!(params={})
      errors = []
      params.each do |key, value|
        type    = config[key][:validate]
        begin
          coercer     = ValidatorFactory.fetch_coercer(type)
          if config[key][:list]
            list        = Array(params[key])
            if  list.empty? && !config[key][:required]
              params[key] = nil
            else
              params[key] = list.map { |_value| coercer.coerce(_value) }
            end
          else
            params[key] = coercer.coerce(value)
          end
        rescue => e
          errors << "#{e} during the coercion of #{key} with value #{value}"
        end
      end
      [errors.empty?, errors]
    end

    def fetch_validator(validate_with, params)
      if validate_with.is_a?(Symbol) 
        return ValidatorFactory.fetch_validator(validate_with).new(params)
      elsif validate_with.respond_to?(:call)
        return TypeValidators::BlockValidator.new(validate_with, params)
      elsif validate_with.is_a?(::Array) && validate_with.length > 0
        logger.warn "Using an array as validator deprecated, Procs are now available and are more powerful than Arrays."
        validate_proc =  Proc.new { |value| validate_with.include?(value) }
        return TypeValidators::BlockValidator.new(validate_proc, params)
      else
        build_custom_validator(validate_with, params)
      end
    end

    private

    def build_custom_validator(klass, params)
      validator = TypeValidators.const_get(klass).new(params)
      if !validator.is_a?(TypeValidators::Abstract)
        raise NameError.new("#{validator.class} should be of type TypeValidators::Abstract");
      end
      return validator
    end

    def validate_attribute_names(params)
      errors = []
      parameter_name_validator = build_task(LogStash::Config::Validators::NameValidator)
      params.each do |attr, value|
        valid, error_msg = parameter_name_validator.valid?(attr, value)
        errors << error_msg unless valid
      end
      return errors.empty?, errors
    end

    def validate_required_params(params)
      errors = []
      required_value_validator = build_task(LogStash::Config::Validators::ExistValueValidator)
      required_values_config   = config.select { |k,v| v[:required] }

      required_values_config.each do |attr, config_attributes|
        valid, error_msg = required_value_validator.valid?(attr, params[attr])
        errors << error_msg unless valid
      end

      return errors.empty?, errors
    end

    def build_task(klass)
       klass.new(config, plugin_type, plugin_name)
    end
  end
end
