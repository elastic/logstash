require "logstash/namespace"
require "logstash/util"

module LogStash::Util::FieldReference
  def compile(str)
    if str[0,1] != '['
      return <<-"CODE"
        lambda do |e, &block|
          return block.call(e, #{str.inspect}) unless block.nil?
          return e[#{str.inspect}]
        end
      CODE
    end

    code = "lambda do |e, &block|\n"
    selectors = str.scan(/(?<=\[).+?(?=\])/)
    selectors.each_with_index do |tok, i|
      last = (i == selectors.count() - 1)
      code << "   # [#{tok}]#{ last ? " (last selector)" : "" }\n"
     
      if last
        code << <<-"CODE"
          return block.call(e, #{tok.inspect}) unless block.nil?
        CODE
      end

      code << <<-"CODE"
        if e.is_a?(Array)
          e = e[#{tok.to_i}]
        else
          e = e[#{tok.inspect}]
        end
        return e if e.nil?
      CODE
      
    end
    code << "return e\nend"
    #puts code
    return code
  end # def compile

  def exec(str, obj, &block)
    @__fieldeval_cache ||= {}
    @__fieldeval_cache[str] ||= eval(compile(str))
    return @__fieldeval_cache[str].call(obj, &block)
  end

  extend self
end # module LogStash::Util::FieldReference
