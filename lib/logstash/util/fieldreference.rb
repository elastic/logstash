# encoding: utf-8
require "logstash/namespace"
require "logstash/util"

module LogStash::Util::FieldReference

  def compile(accessor)
    if accessor[0,1] != '['
      return <<-"CODE"
        lambda do |store, &block|
          return block.nil? ? store[#{accessor.inspect}] : block.call(store, #{accessor.inspect})
        end
      CODE
    end

    code = "lambda do |store, &block|\n"
    selectors = accessor.scan(/(?<=\[).+?(?=\])/)
    selectors.each_with_index do |tok, i|
      last = (i == selectors.count() - 1)
      code << "   # [#{tok}]#{ last ? " (last selector)" : "" }\n"

      if last
        code << <<-"CODE"
          return block.call(store, #{tok.inspect}) unless block.nil?
        CODE
      end

      code << <<-"CODE"
        store = store.is_a?(Array) ? store[#{tok.to_i}] : store[#{tok.inspect}]
        return store if store.nil?
      CODE

    end
    code << "return store\nend"
    #puts code
    return code
  end # def compile

  def exec(accessor, store, &block)
    @__fieldeval_cache ||= {}
    @__fieldeval_cache[accessor] ||= eval(compile(accessor))
    return @__fieldeval_cache[accessor].call(store, &block)
  end

  def set(accessor, value, store)
    # The assignment can fail if the given field reference (accessor) does not exist
    # In this case, we'll want to set the value manually.
    if exec(accessor, store) { |hash, key| hash[key] = value }.nil?
      return (store[accessor] = value) if accessor[0,1] != "["

      # No existing element was found, so let's set one.
      *parents, key = accessor.scan(/(?<=\[)[^\]]+(?=\])/)
      parents.each do |p|
        if store.include?(p)
          store = store[p]
        else
          store[p] = {}
          store = store[p]
        end
      end
      store[key] = value
    end

    return value
  end

  extend self
end # module LogStash::Util::FieldReference
