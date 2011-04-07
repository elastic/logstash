
class LogStashConfigDocGenerator
  COMMENT_RE = /^ *#(.*)/
  RULES = {
    COMMENT_RE => lambda { |m| add_comment(m[1]) },
    /^ *config .*/ => lambda { |m| add_config(m[0]) },
  }

  def parse(string)
    buffer = ""
    string.split("\n").each do |line|

      if line =~ COMMENT_RE
        # nothing
      else
        # Join extended lines
        if line =~ /(, *$)|(\\$)/
          buffer += line.gsub(/\\$/, "")
          next
        end
      end

      p line
    end
  end
end

if __FILE__ == $0
  gen = LogStashConfigDocGenerator.new
  gen.parse(File.new(ARGV[0]).read)
end
