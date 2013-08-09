require "logstash/namespace"
require "logstash/util"

module LogStash::Util::HashEval
  def compile(str)
    if str[0] != '['
      return "lambda { |e, &block| return e[#{str.inspect}] }"
    end

    code = "lambda do |e, &block|\n"
    selectors = str.scan(/(?<=\[).+?(?=\])/)
    selectors.each_with_index do |tok, i|
      last = (i == selectors.count() - 1)
      code << "   # [#{tok}]#{ last ? " (last selector)" : "" }\n"
     
      if last
        code << <<-"CODE"
          block.call(e, #{tok.inspect}) unless block.nil?
        CODE
      end

      code << <<-"CODE"
        if e.is_a?(Array)
          e = e[#{tok.to_i}]
        else
          e = e[#{tok.inspect}]
        end
      CODE
      
    end
    code << "return e\nend"
    return code
  end # def compile

  def exec(str, obj, &block)
    @__fieldeval_cache ||= {}
    @__fieldeval_cache[str] ||= eval(compile(str))
    return @__fieldeval_cache[str].call(obj, &block)
  end

  extend self
end # module LogStash::Util::HashEval
