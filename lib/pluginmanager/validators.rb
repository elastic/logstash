# encoding: utf-8
require "gems"
require "pluginmanager/validators/version"

module LogStash
  module PluginManager

    module Validations

      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods

        def filter_plugin_with(options)
          validators << lambda do |plugin|
            !options.any? { |key| plugin.options.has_key?(key) }
          end
        end

        def validate_plugin_property_with(attribute, criteria={})
          if :version == attribute
            validators << validate_with(LogStash::PluginManager::VersionValidators, criteria)
          end
        end

        def validate_with(klass, criteria)
          klass.validates(criteria)
        end

        def validators
          @@validators ||= []
        end

      end
    end

  end
end
