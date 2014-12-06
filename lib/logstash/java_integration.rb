require "java"

# this is mainly for usage with JrJackson json parsing in :raw mode which genenerates
# Java::JavaUtil::ArrayList and Java::JavaUtil::LinkedHashMap native objects for speed.
# these object already quacks like their Ruby equivalents Array and Hash but they will
# not test for is_a?(Array) or is_a?(Hash), and not support class equivalence Hash === LinkedHashMap.new
# used in class case statements like: case o; when Hash ...
#
# we do not want to include tests for all Java classes everywhere. see LogStash::JSon.

class Java::JavaUtil::ArrayList
  # have ArrayList objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Array
    super
  end
end

class Java::JavaUtil::Vector
  # have Vector objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Array
    super
  end
end

class Java::JavaUtil::LinkedHashMap
  # have LinkedHashMap objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Hash
    super
  end

  # see https://github.com/jruby/jruby/issues/1249
  if ENV_JAVA['java.specification.version'] >= '1.8'
    def merge(other)
      dup.merge!(other)
    end
  end
end

class Java::JavaUtil::HashMap
  # have HashMap objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Hash
    super
  end

  # see https://github.com/jruby/jruby/issues/1249
  if ENV_JAVA['java.specification.version'] >= '1.8'
    def merge(other)
      dup.merge!(other)
    end
  end
end

class Java::JavaUtil::TreeMap
  # have TreeMap objects report is_a?(Array) == true
  def is_a?(clazz)
    return true if clazz == Hash
    super
  end

  # see https://github.com/jruby/jruby/issues/1249
  if ENV_JAVA['java.specification.version'] >= '1.8'
    def merge(other)
      dup.merge!(other)
    end
  end
end

class Array
  # enable class equivalence between Array and ArrayList
  # so that ArrayList will work with case o when Array ...
  def self.===(other)
    return true if other.is_a?(Java::JavaUtil::List)
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
