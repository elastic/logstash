# encoding: utf-8
require "concurrent"
require "logstash/event"
require "logstash/instrument/metric_type"

module LogStash module Instrument
  # The Metric store the data structure that make sure the data is
  # saved in a retrievable way, this is a wrapper around multiples ConcurrentHashMap
  # acting as a tree like structure.
  class MetricStore
    class NamespacesExpectedError < StandardError; end
    class MetricNotFound < StandardError; end

    KEY_PATH_SEPARATOR = "/".freeze

    # Lets me a bit flexible on the coma usage in the path
    # definition
    FILTER_KEYS_SEPARATOR = /\s?*,\s*/.freeze

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
    # This method support the following queries
    #
    # stats/pipelines/pipeline_X
    # stats/pipelines/pipeline_X,pipeline_2
    # stats/os,jvm
    #
    # If you use the `,` on a key the metric store will return the both values at that level
    #
    # The returned hash will keep the same structure as it had in the `Concurrent::Map`
    # but will be a normal ruby hash. This will allow the api to easily seriliaze the content
    # of the map
    #
    # @param [Array] The path where values should be located
    # @return nil if the values are not found
    def get_with_path(path)
      key_paths = path.gsub(/^#{KEY_PATH_SEPARATOR}+/, "").split(KEY_PATH_SEPARATOR)
      get(*key_paths)
    end

    # Use an array of symbols instead of path
    def get(*key_paths)
      # Normalize the symbols access
      key_paths.map(&:to_sym)
      new_hash = Hash.new

      get_recursively(key_paths, @store, new_hash)

      new_hash
    end

    # Return all the individuals Metric,
    # This call mimic a Enum's each if a block is provided
    def each(path = nil, &block)
      metrics = if path.nil?
        get_all
      else
        transform_to_array(get_with_path(path))
      end

      block_given? ? metrics.each(&block) : metrics
    end
    alias_method :all, :each

    private
    def get_all
      each_recursively(@store).flatten
    end

    def get_recursively(key_paths, map, new_hash)
      key_candidates = extract_filter_keys(key_paths.shift)

      key_candidates.each do |key_candidate|
        raise MetricNotFound, "For path: #{key_candidate}" if map[key_candidate].nil?

        if key_paths.empty? # End of the user requested path
          if map[key_candidate].is_a?(Concurrent::Map)
            new_hash[key_candidate] = transform_to_hash(map[key_candidate])
          else
            new_hash[key_candidate] = map[key_candidate]
          end
        else
          if map[key_candidate].is_a?(Concurrent::Map)
            new_hash[key_candidate] = get_recursively(key_paths, map[key_candidate], {})
          else
            new_hash[key_candidate] = map[key_candidate]
          end
        end
      end
      return new_hash
    end

    def extract_filter_keys(key)
      key.to_s.strip.split(FILTER_KEYS_SEPARATOR).map(&:to_sym)
    end

    def transform_to_array(map)
      map.values.collect do |value|
        value.is_a?(Hash) ? transform_to_array(value) : value
      end.flatten
    end

    def transform_to_hash(map, new_hash = Hash.new)
      map.each_pair do |key, value|
        if value.is_a?(Concurrent::Map)
          new_hash[key] = {}
          transform_to_hash(value, new_hash[key])
        else
          new_hash[key] = value
        end
      end

      return new_hash
    end

    # Recursively fetch only the leaf node that should be an instance
    # of the `MetricType`
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
    # value for the path, if any part of the path is not found it will
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
