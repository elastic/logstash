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
      target[key] = value
    end

    def strict_set(accessor, value)
      set(accessor, strict_value(value))
    end

    def del(accessor)
      target, key = lookup(accessor)
      target.delete(key)
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

    def strict_value(value)
      case value
      when String
        raise("expected UTF-8 encoding for value=#{value}, encoding=#{value.encoding.inspect}") unless value.encoding == Encoding::UTF_8
        raise("invalid UTF-8 encoding for value=#{value}, encoding=#{value.encoding.inspect}") unless value.valid_encoding?
        value
      when Array
        value.each{|v| strict_value(v)} # don't map, return original object
        value
      else
        value
      end
    end

  end # class Accessors
end # module LogStash::Util
