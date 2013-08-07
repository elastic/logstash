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
        v = e[#{tok.inspect}]
        if v.is_a?(Array)
          e = v[#{tok.to_i}]
        else
          e = e[#{tok.inspect}]
        end
      CODE
      
    end
    code << "return e\nend"
    return code
  end # def []
  extend self
end # module LogStash::Util::HashEval
