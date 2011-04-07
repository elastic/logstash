require "rubygems"

$: << File.join(File.dirname(__FILE__), "..", "lib")

class LogStashConfigDocGenerator
  COMMENT_RE = /^ *#(.*)/

  def initialize
    @rules = {
      COMMENT_RE => lambda { |m| add_comment(m[1]) },
      /^ *config .*/ => lambda { |m| add_config(m[0]) },
      /^ *config_name .*/ => lambda { |m| set_config_name(m[0]) },
      /^ *(class|def|module) / => lambda { |m| clear_comments },
    }
  end

  def parse(string)
    buffer = ""
    @comments = []
    @settings = {}
    string.split("\n").each do |line|
      # Join long lines
      if line =~ COMMENT_RE
        # nothing
      else
        # Join extended lines
        if line =~ /(, *$)|(\\$)/
          buffer += line.gsub(/\\$/, "")
          next
        end
      end

      line = buffer + line
      buffer = ""

      @rules.each do |re, action|
        m = re.match(line)
        if m
          action.call(m)
        end
      end # RULES.each
    end # string.split("\n").each
  end

  def add_comment(comment)
    @comments << comment
  end

  def add_config(code)
    # call the code, which calls 'config' in this class.
    # This will let us align comments with config options.
    name, opts = eval(code)
    @settings[name] = opts.merge(:description => @comments.join("\n"))
    clear_comments
  end # def add_config

  def set_config_name(code)
    name = eval(code)
    @name = name
  end # def set_config_name

  # pretend to be the config DSL and just get the name
  def config(name, opts={})
    return name, opts
  end # def config

  # pretend to be the config dsl's 'config_name' method
  def config_name(name)
    return name
  end # def config_name

  def clear_comments
    @comments.clear
  end # def clear_comments

  def generate(file)
    string = File.new(file).read
    parse(string)
    require file
    puts LogStash::Config::Registry.registry[@name]
    @settings.each do |name, description|
      p name => description
    end
  end
end

if __FILE__ == $0
  gen = LogStashConfigDocGenerator.new
  gen.generate(ARGV[0])
end
