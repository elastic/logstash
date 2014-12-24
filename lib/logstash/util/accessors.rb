# encoding: utf-8

require "logstash/namespace"
require "logstash/util"

module LogStash::Util

  # PathCache is a singleton which globally caches a parsed fields path for the path to the
  # container hash and key in that hash.
  module PathCache
    extend self

    def get(accessor)
      @cache ||= {}
      @cache[accessor] ||= parse(accessor)
    end

    def parse(accessor)
      path = accessor.split(/[\[\]]/).select{|s| !s.empty?}
      [path.pop, path]
    end
  end

  # Accessors uses a lookup table to speedup access of an accessor field of the type
  # "[hello][world]" to the underlying store hash into {"hello" => {"world" => "foo"}}
  class Accessors

    def initialize(store)
      @store = store
      @lut = {}
    end

    def get(accessor)
      target, key = lookup(accessor)
      target.is_a?(Array) ? target[key.to_i] : target[key]
    end

    def set(accessor, value)
      target, key = lookup(accessor)
      target[target.is_a?(Array) ? key.to_i : key] = value
    end

    def strict_set(accessor, value)
      set(accessor, LogStash::Event.validate_value(value))
    end

    def del(accessor)
      target, key = lookup(accessor)
      target.is_a?(Array) ? target.delete_at(key.to_i) : target.delete(key)
    end

    private

    def lookup(accessor)
      @lut[accessor] ||= store_path(accessor)
    end

    def store_path(accessor)
      key, path = PathCache.get(accessor)
      target = path.inject(@store) {|r, k| r[r.is_a?(Array) ? k.to_i : k] ||= {}}
      [target, key]
    end
  end # class Accessors
end # module LogStash::Util
