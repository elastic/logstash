# encoding: utf-8
require "java"

# this is mainly for usage with JrJackson json parsing in :raw mode which generates
# Java::JavaUtil::ArrayList and Java::JavaUtil::LinkedHashMap native objects for speed.
# these object already quacks like their Ruby equivalents Array and Hash but they will
# not test for is_a?(Array) or is_a?(Hash) and we do not want to include tests for
# both classes everywhere. see LogStash::JSon.

class Array
  # enable class equivalence between Array and ArrayList
  # so that ArrayList will work with case o when Array ...
  def self.===(other)
    return true if other.is_a?(Java::JavaUtil::Collection)
    super
  end
end

class Hash
  # enable class equivalence between Hash and LinkedHashMap
  # so that LinkedHashMap will work with case o when Hash ...
  def self.===(other)
    return true if other.is_a?(Java::JavaUtil::Map)
    super
  end
end

# map_mixin to patch LinkedHashMap and HashMap. it must be done directly on the classes,
# using a module mixin does not work, and injecting in the Map interface does not work either
# but injecting in the class works.

map_mixin = lambda do
  # this is a temporary fix to solve a bug in JRuby where classes implementing the Map interface, like LinkedHashMap
  # have a bug in the has_key? method that is implemented in the Enumerable module that is somehow mixed in the Map interface.
  # this bug makes has_key? (and all its aliases) return false for a key that has a nil value.
  # Only LinkedHashMap is patched here because patching the Map interface is not working.
  # TODO find proper fix, and submit upstream
  # relevant JRuby files:
  # https://github.com/jruby/jruby/blob/master/core/src/main/ruby/jruby/java/java_ext/java.util.rb
  # https://github.com/jruby/jruby/blob/master/core/src/main/java/org/jruby/java/proxies/MapJavaProxy.java
  def has_key?(key)
    self.containsKey(key)
  end
  alias_method :include?, :has_key?
  alias_method :member?, :has_key?
  alias_method :key?, :has_key?

  # Java 8 Map implements a merge method with a different signature from
  # the Ruby Hash#merge. see https://github.com/jruby/jruby/issues/1249
  # this can be removed when fixed upstream
  if ENV_JAVA['java.specification.version'] >= '1.8'
    def merge(other)
      dup.merge!(other)
    end
  end
end

Java::JavaUtil::LinkedHashMap.module_exec(&map_mixin)
Java::JavaUtil::HashMap.module_exec(&map_mixin)

module java::util::Map
  # have Map objects like LinkedHashMap objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Hash
    super
  end
end

module java::util::Collection
  # have Collections objects like ArrayList report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Array
    super
  end

  # support the Ruby Array delete method on a Java Collection
  def delete(o)
    self.removeAll([o]) ? o : block_given? ? yield : nil
  end

  def compact
    duped = Java::JavaUtil::ArrayList.new(self)
    duped.compact!
    duped
  end

  def compact!
    size_before = self.size
    self.removeAll(java::util::Collections.singleton(nil))
    if size_before == self.size
      nil
    else
      self
    end
  end

  # support the Ruby intersection method on Java Collection
  def &(other)
    # transform self into a LinkedHashSet to remove duplicates and preserve order as defined by the Ruby Array intersection contract
    duped = Java::JavaUtil::LinkedHashSet.new(self)
    duped.retainAll(other)
    duped
  end

  # support the Ruby union method on Java Collection
  def |(other)
    # transform self into a LinkedHashSet to remove duplicates and preserve order as defined by the Ruby Array union contract
    duped = Java::JavaUtil::LinkedHashSet.new(self)
    duped.addAll(other)
    duped
  end

  def inspect
    "<#{self.class.name}:#{self.hashCode} #{self.to_a(&:inspect)}>"
  end
end
