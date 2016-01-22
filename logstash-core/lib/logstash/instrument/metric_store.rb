# encoding: utf-8
require "concurrent"
require "logstash/event"
require "logstash/instrument/metric_type"

module LogStash module Instrument
  # The Metric store the data structure that make sure the data is
  # saved in a retrievable way, this is a wrapper around multiples ConcurrentHashMap
  # acting as a tree like structure.
  class MetricStore
    class NamespacesExpectedError < Exception; end

    def initialize
      # We keep the structured cache to allow
      # the api to search the content of the differents nodes
      @store = Concurrent::Map.new
    end

    # This method use the namespace and key to search the corresponding value of
    # the hash, if it doesn't exist it will create the appropriate namespaces
    # path in the hash and return `new_value`
    #
    # @param [Array] The path where the values should be located
    # @param [Object] The default object if the value is not found in the path
    # @return [Object] Return the new_value of the retrieve object in the tree
    def fetch_or_store(namespaces, key, default_value = nil)
      fetch_or_store_namespaces(namespaces).fetch_or_store(key, block_given? ? yield(key) : default_value)
    end

    # This method allow to retrieve values for a specific path,
    #
    #
    # @param [Array] The path where values should be located
    # @return nil if the values are not found
    def get(*key_paths)
      get_recursively(key_paths, @store)
    end

    # Return all the individuals Metric
    #
    # @return [Array] An array of all metric transformed in `Logstash::Event`, or in case of passing a block it yields
    # the expected value as other Enumerable implementations.
    def each(&block)
      data = each_recursively(@store).flatten
      if block_given?
        data.each(&block)
      else
        return data
      end
    end

    private
    def get_recursively(key_paths, map)
      key_candidate = key_paths.shift

      if key_paths.empty?
        return map[key_candidate]
      else 
        next_map = map[key_candidate]

        if next_map.is_a?(Concurrent::Map)
          return get_recursively(key_paths, next_map)
        else
          return nil
        end
      end
    end

    def each_recursively(values)
      events = []
      values.each_value do |value|
        if value.is_a?(Concurrent::Map)
          events << each_recursively(value) 
        else
          events << value
        end
      end
      return events
    end

    # This method iterate through the namespace path and try to find the corresponding 
    # value for the path, if the any part of the path is not found it will 
    # create it.
    #
    # @param [Array] The path where values should be located
    # @raise [ConcurrentMapExpected] Raise if the retrieved object isn't a `Concurrent::Map`
    # @return [Concurrent::Map] Map where the metrics should be saved
    def fetch_or_store_namespaces(namespaces_path)
      path_map = fetch_or_store_namespace_recursively(@store, namespaces_path)

      # This mean one of the namespace and key are colliding
      # and we have to deal it upstream.
      unless path_map.is_a?(Concurrent::Map)
        raise NamespacesExpectedError, "Expecting a `Namespaces` but found class:  #{path_map.class.name} for namespaces_path: #{namespaces_path}"
      end

      return path_map
    end

    # Recursively fetch or create the namespace paths through the `MetricStove`
    # This algorithm use an index to known which keys to search in the map.
    # This doesn't cloning the array if we want to give a better feedback to the user
    #
    # @param [Concurrent::Map] Map to search for the key
    # @param [Array] List of path to create
    # @param [Fixnum] Which part from the list to create
    #
    def fetch_or_store_namespace_recursively(map, namespaces_path, idx = 0)
      current = namespaces_path[idx]
      
      # we are at the end of the namespace path, break out of the recursion
      return map if current.nil?

      new_map = map.fetch_or_store(current) { Concurrent::Map.new }
      return fetch_or_store_namespace_recursively(new_map, namespaces_path, idx + 1)
    end
  end
end; end
