require "java"

# this is mainly for usage with JrJackson json parsing in :raw mode which genenerates
# Java::JavaUtil::ArrayList and Java::JavaUtil::LinkedHashMap native objects for speed.
# these object already quacks like their Ruby equivalents Array and Hash but they will
# not test for is_a?(Array) or is_a?(Hash) and we do not want to include tests for
# both classes everywhere. see LogStash::JSon.

class Java::JavaUtil::ArrayList
  # have ArrayList objects report is_a?(Array) == true
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
end

class Array
  # enable class equivalence between Array and ArrayList
  # so that ArrayList will work with case o when Array ...
  def self.===(other)
    return true if other.is_a?(Java::JavaUtil::ArrayList)
    super
  end
end

class Hash
  # enable class equivalence between Hash and LinkedHashMap
  # so that LinkedHashMap will work with case o when Hash ...
  def self.===(other)
    return true if other.is_a?(Java::JavaUtil::LinkedHashMap)
    super
  end
end
