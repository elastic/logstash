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

require 'thread_safe/cache'

module LogStash
  ##
  # `PluginMetadata` provides a space to store key/value metadata about a plugin, typically metadata about
  # external resources that can be gleaned during plugin registration.
  #
  # Data should not be persisted across pipeline reloads, and should be cleaned up after a pipeline reload
  #
  #  - It MUST NOT be used to store processing state
  #  - It SHOULD NOT be updated frequently.
  #  - Individual metadata keys MUST be Symbols and SHOULD NOT be dynamically generated
  #
  # USAGE FROM PLUGINS
  # ------------------
  #
  # Since we allow plugins to be updated, it is important to introduce bindings to new Logstash features in a way
  # that doesn't break when installed onto a Logstash that doesn't have those features, e.g.:
  #
  # ~~~
  #
  # plugin_metadata.set(:foo, bar) if defined?(plugin_metadata?)
  #
  # ~~~
  #
  # @since 7.1
  class PluginMetadata
    include LogStash::Util::Loggable

    REGISTRY = ThreadSafe::Cache.new unless defined?(REGISTRY)

    class << self
      ##
      # Get the PluginMetadata object corresponding to the given plugin id
      #
      # @param plugin_id [String]
      #
      # @return [PluginMetadata]: the metadata object for the provided `plugin_id`; if no
      #                           metadata object exists, it will be created.
      def for_plugin(plugin_id)
        REGISTRY.compute_if_absent(plugin_id) { PluginMetadata.new }
      end

      ##
      # Determine if we have an existing PluginMetadata object for the given plugin id
      # This allows us to avoid creating a metadata object if we don't already have one.
      #
      # @param plugin_id [String]
      #
      # @return [Boolean]
      def exists?(plugin_id)
        REGISTRY.key?(plugin_id)
      end

      ##
      # Deletes, and then clears the contents of an existing PluginMetadata object for the given plugin id if one exists
      #
      # @param plugin_id [String]
      #
      # @return [Boolean]
      def delete_for_plugin(plugin_id)
        logger.debug("Removing metadata for plugin #{plugin_id}")
        old_registry = REGISTRY.delete(plugin_id)
        old_registry.clear unless old_registry.nil?
      end

      ##
      # @api private
      def reset!
        REGISTRY.clear
      end
    end

    ##
    # @see [LogStash::PluginMetadata#for_plugin(String)]
    # @api private
    def initialize
      @datastore = ThreadSafe::Cache.new
    end

    ##
    # Set the metadata key for this plugin, returning the previous value (if any)
    #
    # @param key [Symbol]
    # @param value [Object]
    #
    # @return [Object]
    def set(key, value)
      if value.nil?
        @datastore.delete(key)
      else
        @datastore.get_and_set(key, value)
      end
    end

    ##
    # Get the metadata value for the given key on this plugin
    #
    # @param key [Symbol]
    #
    # @return [Object]: the value object associated with the given key on this
    #                   plugin, or nil if no value is associated
    def get(key)
      @datastore.get(key)
    end

    ##
    # Determine whether specific key/value metadata exists for this plugin
    #
    # @param key [Symbol]: the key
    #
    # @return [Boolean]: true if the plugin includes metadata for the key
    def set?(key)
      @datastore.key?(key)
    end

    ##
    # Delete the metadata key for this plugin, returning the previous value (if any)
    #
    # @param key [Symbol]
    #
    # @return [Object]
    def delete(key)
      @datastore.delete(key)
    end

    ##
    # Clear all metadata keys for this plugin
    #
    # @return [Object]
    def clear
      @datastore.clear
    end
  end
end