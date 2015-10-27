# encoding: utf-8
require "logstash/namespace"
require "logstash/util"
require "thread_safe"

module LogStash::Util

  # PathCache is a singleton which globally caches the relation between a field reference and its
  # decomposition into a [key, path array] tuple. For example the field reference [foo][bar][baz]
  # is decomposed into ["baz", ["foo", "bar"]].
  module PathCache
    extend self

    # requiring libraries and defining constants is thread safe in JRuby so
    # PathCache::CACHE will be corretly initialized, once, when accessors.rb
    # will be first required
    CACHE = ThreadSafe::Cache.new

    def get(field_reference)
      # the "get_or_default(x, nil) || put(x, parse(x))" is ~2x faster than "get || put" because the get call is
      # proxied through the JRuby JavaProxy op_aref method. the correct idiom here would be to use
      # "compute_if_absent(x){parse(x)}" but because of the closure creation, it is ~1.5x slower than
      # "get_or_default || put".
      # this "get_or_default || put" is obviously non-atomic which is not really important here
      # since all threads will set the same value and this cache will stabilize very quickly after the first
      # few events.
      CACHE.get_or_default(field_reference, nil) || CACHE.put(field_reference, parse(field_reference))
    end

    def parse(field_reference)
      path = field_reference.split(/[\[\]]/).select{|s| !s.empty?}
      [path.pop, path]
    end
  end

  # Accessors uses a lookup table to speedup access of a field reference of the form
  # "[hello][world]" to the underlying store hash into {"hello" => {"world" => "foo"}}
  class Accessors

    # @param store [Hash] the backing data store field refereces point to
    def initialize(store)
      @store = store

      # @lut is a lookup table between a field reference and a [target, key] tuple
      # where target is the containing Hash or Array for key in @store.
      # this allows us to directly access the containing object for key instead of
      # walking the field reference path into the inner @store objects
      @lut = {}
    end

    # @param field_reference [String] the field reference
    # @return [Object] the value in @store for this field reference
    def get(field_reference)
      target, key = lookup(field_reference)
      return nil unless target
      target.is_a?(Array) ? target[key.to_i] : target[key]
    end

    # @param field_reference [String] the field reference
    # @param value [Object] the value to set in @store for this field reference
    # @return [Object] the value set
    def set(field_reference, value)
      target, key = lookup_or_create(field_reference)
      target[target.is_a?(Array) ? key.to_i : key] = value
    end

    # @param field_reference [String] the field reference to remove
    # @return [Object] the removed value in @store for this field reference
    def del(field_reference)
      target, key = lookup(field_reference)
      return nil unless target
      target.is_a?(Array) ? target.delete_at(key.to_i) : target.delete(key)
    end

    # @param field_reference [String] the field reference to test for inclusion in the store
    # @return [Boolean] true if the store contains a value for this field reference
    def include?(field_reference)
      target, key = lookup(field_reference)
      return false unless target

      target.is_a?(Array) ? !target[key.to_i].nil? : target.include?(key)
    end

    private

    # retrieve the [target, key] tuple associated with this field reference
    # @param field_reference [String] the field referece
    # @return [[Object, String]] the  [target, key] tuple associated with this field reference
    def lookup(field_reference)
      @lut[field_reference] ||= find_target(field_reference)
    end

    # retrieve the [target, key] tuple associated with this field reference and create inner
    # container objects if they do not exists
    # @param field_reference [String] the field referece
    # @return [[Object, String]] the  [target, key] tuple associated with this field reference
    def lookup_or_create(field_reference)
      @lut[field_reference] ||= find_or_create_target(field_reference)
    end

    # find the target container object in store for this field reference
    # @param field_reference [String] the field referece
    # @return [Object] the target container object in store associated with this field reference
    def find_target(field_reference)
      key, path = PathCache.get(field_reference)
      target = path.inject(@store) do |r, k|
        return nil unless r
        r[r.is_a?(Array) ? k.to_i : k]
      end
      target ? [target, key] : nil
    end

    # find the target container object in store for this field reference and create inner
    # container objects if they do not exists
    # @param field_reference [String] the field referece
    # @return [Object] the target container object in store associated with this field reference
    def find_or_create_target(accessor)
      key, path = PathCache.get(accessor)
      target = path.inject(@store) {|r, k| r[r.is_a?(Array) ? k.to_i : k] ||= {}}
      [target, key]
    end
  end # class Accessors
end # module LogStash::Util
