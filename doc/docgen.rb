require "rubygems"

# TODO(sissel): Currently this doc generator doesn't follow ancestry, so
# LogStash::Input::Amqp inherits Base, but we don't parse the base file.
# We need this, though.

$: << File.join(File.dirname(__FILE__), "..", "lib")

class LogStashConfigDocGenerator
  COMMENT_RE = /^ *#(?: (.*)| *$)/

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
  end # def parse
 
  def add_comment(comment)
    @comments << comment
  end # def add_comment

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
    require "logstash/inputs/base"
    require "logstash/filters/base"
    require "logstash/outputs/base"
    string = File.new(file).read
    parse(string)
    require file
    klass = LogStash::Config::Registry.registry[@name]
    if klass.ancestors.include?(LogStash::Inputs::Base)
      section = "inputs"
    elsif klass.ancestors.include?(LogStash::Filters::Base)
      section = "filters"
    elsif klass.ancestors.include?(LogStash::Outputs::Base)
      section = "outputs"
    end

    # TODO(sissel): probably should use ERB for this.
    puts "# " + LogStash::Config::Registry.registry[@name].to_s
    puts
    puts "Usage example:"
    puts 
    puts [
      "#{section} {",
      "  #{@name} {",
      "    # ... settings ...",
      "  }",
      "}",
    ].map { |l| "    #{l}" }.join("\n")

    # TODO(sissel): include description of this plugin, maybe use
    # rdoc to pull this?
    @settings.sort { |a,b| a.first.to_s <=> b.first.to_s }.each do |name, config|
      if name.is_a?(Regexp)
        puts "## /#{name}/ (any config setting matching this regex)"
      else
        puts "## #{name}"
      end
      puts
      puts config[:description]
      puts
      puts "* Value expected is: #{config[:validate] or "string"}"
      puts "* This is a required setting" if config[:required]
      puts "* Default value is: #{config[:default]}" if config.include?(:default)
      puts 
    end
  end # def generate
end # class LogStashConfigDocGenerator

if __FILE__ == $0
  gen = LogStashConfigDocGenerator.new
  gen.generate(ARGV[0])
end
