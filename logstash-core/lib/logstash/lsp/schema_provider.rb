# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/plugins/registry"

module LogStash
  module Lsp
    # Provides plugin schema information for LSP features
    class SchemaProvider
      PLUGIN_TYPES = [:input, :filter, :output, :codec].freeze

      # Common config options inherited from base classes that shouldn't be suggested first
      COMMON_OPTIONS = %w[
        enable_metric id type codec tags add_field remove_field
        add_tag remove_tag periodic_flush
      ].freeze

      def initialize
        @schema_cache = nil
        @mutex = Mutex.new
      end

      # Get all plugin names for a section type
      # @param type [Symbol] :input, :filter, :output, or :codec
      # @return [Array<String>] list of plugin names
      def plugin_names(type)
        schema[type.to_sym]&.keys || []
      end

      # Get config options for a specific plugin
      # @param type [Symbol] plugin type
      # @param plugin_name [String] plugin name
      # @return [Hash] config option name => details
      def plugin_options(type, plugin_name)
        schema.dig(type.to_sym, plugin_name, :options) || {}
      end

      # Get full details for a specific option
      # @param type [Symbol] plugin type
      # @param plugin_name [String] plugin name
      # @param option_name [String] option name
      # @return [Hash, nil] option details or nil
      def option_details(type, plugin_name, option_name)
        plugin_options(type, plugin_name)[option_name]
      end

      # Get plugin description/documentation
      # @param type [Symbol] plugin type
      # @param plugin_name [String] plugin name
      # @return [String, nil] plugin description
      def plugin_description(type, plugin_name)
        schema.dig(type.to_sym, plugin_name, :description)
      end

      # Check if a plugin exists
      # @param type [Symbol] plugin type
      # @param plugin_name [String] plugin name
      # @return [Boolean]
      def plugin_exists?(type, plugin_name)
        schema.dig(type.to_sym, plugin_name).nil? == false
      end

      # Get the full schema (lazily built)
      # @return [Hash] full schema structure
      def schema
        return @schema_cache if @schema_cache

        @mutex.synchronize do
          return @schema_cache if @schema_cache
          @schema_cache = build_schema
        end
      end

      # Force rebuild of schema cache
      def refresh!
        @mutex.synchronize do
          @schema_cache = nil
        end
      end

      private

      def build_schema
        schema = {}

        PLUGIN_TYPES.each do |type|
          schema[type] = {}
        end

        # First, get already-loaded plugins from registry
        PLUGIN_TYPES.each do |type|
          begin
            plugins = LogStash::PLUGIN_REGISTRY.plugins_with_type(type)
            plugins.each do |plugin_class|
              add_plugin_to_schema(schema, type, plugin_class)
            end
          rescue => e
            # Continue on error
          end
        end

        # Then discover ALL installed plugins via gems
        begin
          discover_installed_plugins(schema)
        rescue => e
          # Continue on error
        end

        # Also scan all integration gems directly (in case they weren't in the registry)
        begin
          discover_all_integration_gems(schema)
        rescue => e
          # Continue on error
        end

        schema
      end

      def discover_installed_plugins(schema)
        # Get all installed logstash plugin gems
        installed_plugins = LogStash::Plugins::Registry::GemRegistry.logstash_plugins

        installed_plugins.each do |plugin_context|
          begin
            type = plugin_context.type.to_sym
            name = plugin_context.name

            # Handle integration plugins specially - they contain multiple plugins
            if type == :integration
              discover_integration_plugins(schema, name)
              next
            end

            # Skip if not a known type or already loaded
            next unless PLUGIN_TYPES.include?(type)
            next if schema[type].key?(name)

            # Try to load the plugin class
            plugin_class = load_plugin_class(type, name)
            next unless plugin_class

            add_plugin_to_schema(schema, type, plugin_class)
          rescue => e
            # Skip plugins that fail to load
          end
        end
      end

      def discover_integration_plugins(schema, integration_name)
        # Integration plugins bundle multiple plugins
        # The provided plugins are listed in gem metadata["integration_plugins"]
        begin
          gem_spec = Gem::Specification.find_by_name("logstash-integration-#{integration_name}")
          return unless gem_spec

          # Check if this is actually an integration plugin
          return unless gem_spec.metadata && gem_spec.metadata["logstash_group"] == "integration"

          # Get the list of plugins this integration provides
          provided_plugins = gem_spec.metadata["integration_plugins"]
          return unless provided_plugins

          # Parse the comma-separated list of plugin names
          # Format: "logstash-input-jdbc,logstash-filter-jdbc_static,..."
          provided_plugins.split(",").each do |full_plugin_name|
            full_plugin_name = full_plugin_name.strip
            # Parse: logstash-{type}-{name}
            match = full_plugin_name.match(/^logstash-(input|filter|output|codec)-(.+)$/)
            next unless match

            type = match[1].to_sym
            plugin_name = match[2]
            next if schema[type].key?(plugin_name)

            # Try to load and add this plugin
            begin
              require "logstash/#{type}s/#{plugin_name}"
              plugin_class = namespace_lookup(type, plugin_name)
              add_plugin_to_schema(schema, type, plugin_class) if plugin_class
            rescue LoadError, NameError => e
              # Skip plugins that can't be loaded
            end
          end
        rescue Gem::MissingSpecError
          # Gem not found, try scanning installed gems for integration plugins
          discover_all_integration_gems(schema)
        end
      end

      def discover_all_integration_gems(schema)
        # Scan all installed gems for integration plugins
        ::Gem::Specification.find_all.each do |spec|
          next unless spec.metadata
          next unless spec.metadata["logstash_plugin"] == "true"
          next unless spec.metadata["logstash_group"] == "integration"

          provided_plugins = spec.metadata["integration_plugins"]
          next unless provided_plugins

          provided_plugins.split(",").each do |full_plugin_name|
            full_plugin_name = full_plugin_name.strip
            match = full_plugin_name.match(/^logstash-(input|filter|output|codec)-(.+)$/)
            next unless match

            type = match[1].to_sym
            plugin_name = match[2]
            next if schema[type].key?(plugin_name)

            begin
              require "logstash/#{type}s/#{plugin_name}"
              plugin_class = namespace_lookup(type, plugin_name)
              add_plugin_to_schema(schema, type, plugin_class) if plugin_class
            rescue LoadError, NameError => e
              # Skip plugins that can't be loaded
            end
          end
        end
      end

      def load_plugin_class(type, name)
        # First check if already in namespace
        klass = namespace_lookup(type, name)
        return klass if klass

        # Try to require it
        begin
          require "logstash/#{type}s/#{name}"
          namespace_lookup(type, name)
        rescue LoadError
          nil
        end
      end

      def namespace_lookup(type, name)
        type_const = "#{type.to_s.capitalize}s"
        namespace = LogStash.const_get(type_const)
        klass_sym = namespace.constants.find do |c|
          klass = namespace.const_get(c)
          klass.respond_to?(:config_name) && klass.config_name == name
        end
        klass_sym ? namespace.const_get(klass_sym) : nil
      rescue NameError
        nil
      end

      def add_plugin_to_schema(schema, type, plugin_class)
        return unless plugin_class.respond_to?(:config_name) && plugin_class.respond_to?(:get_config)

        plugin_name = plugin_class.config_name
        return if plugin_name.nil? || plugin_name.empty?
        return if schema[type].key?(plugin_name)  # Already added

        schema[type][plugin_name] = extract_plugin_schema(plugin_class)
      end

      def extract_plugin_schema(plugin_class)
        config = plugin_class.get_config || {}

        {
          :class_name => plugin_class.name,
          :description => extract_class_description(plugin_class),
          :options => extract_options(config)
        }
      end

      def extract_options(config)
        options = {}

        config.each do |name, attrs|
          options[name] = {
            :type => normalize_type(attrs[:validate]),
            :default => attrs[:default],
            :required => attrs[:required] || false,
            :deprecated => attrs[:deprecated] || false,
            :obsolete => attrs[:obsolete] || false,
            :list => attrs[:list] || false,
            :description => attrs[:description],
            :common => COMMON_OPTIONS.include?(name)
          }
        end

        options
      end

      def normalize_type(validate)
        case validate
        when Symbol
          validate.to_s
        when Array
          # Enumerated values like ["plain", "json"]
          { :enum => validate }
        when Regexp
          { :pattern => validate.source }
        when nil
          "any"
        else
          validate.to_s
        end
      end

      def extract_class_description(plugin_class)
        # Try to get description from class-level documentation
        # This is a placeholder - in practice, descriptions come from
        # static parsing of source files (see logstash-docgen)
        nil
      end
    end
  end
end
