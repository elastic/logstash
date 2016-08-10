# encoding: utf-8
require "logstash/namespace"
require_relative "abstract_validator"

module LogStash::Config

  module Validators

  ##
  # Make sure required values have a value.
  ##

  class ExistValueValidator < AbstractValidator

    attr_reader :config_required_fields, :config_required_keys

    def initialize(config, plugin_type, plugin_name)
      super
      @config_required_fields = config.select { |k,v| v[:required] }
      @config_required_keys   = config_required_fields.map { |k,v| k }
    end

    def valid?(key, value)
      if !verify_required_key(key, value)
        error_msg = I18n.t("logstash.runner.configuration.setting_missing", :setting => key, :plugin => plugin_name, :type => plugin_type)
        @logger.error(error_msg) if @logger.error?
        return false, error_msg
      end
      return true, ""
    end

    private

    def verify_required_key(key, value)
      return true if !config_required_keys.include?(key) # if the key is not required one return true
      if key.is_a?(Regexp)
        return true
      end
      !is_empty?(config_required_fields[key], value)
    end

    def is_empty?(config, value)
      value.nil? || (config[:list] && Array(value).empty?)
    end
  end

  ##
  # Verify that the config values defined are valid ones, this means the configuration
  # names are inside the set defined while creating the plugin.
  ##
  class NameValidator < AbstractValidator

    attr_reader :valid_config_names

    def initialize(config, plugin_type, plugin_name)
      super
      @valid_config_names = config.keys
    end
    # Return true if the parameter name is valid, false otherwise
    def valid?(key, value)
      if !verify_invalid_name(key)
        error_msg = "Unknown setting '#{key}' for #{plugin_name}"
        @logger.error(error_msg) if @logger.error?
        return false, error_msg
      end
      return true, ""
    end

    private

    def verify_invalid_name(name)
      if name.is_a?(String)
        valid_config_names.include?(name)
      elsif name.is_a?(Regexp)
        !valid_config_names.select { |s| s.match(name) }.empty?
      else
        false
      end
    end

    def verify_required_name(key, value)
      return true if config[key][:required]  #we've to be sure keys are always going to be present.
      ## if the key is a Regexp and there is no key that match the regexp return false.
      if key.is_a?(Regexp)
        return true # should be extended properly
      elsif is_empty?(config[key], value)
        return false
      else
        true
      end
      ## if required, but no value in the parameters is setup
    end

    def is_empty?(config, value)
      value.nil? || (config[:list] && Array(value).empty?)
    end

  end

  end
end
