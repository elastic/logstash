require "rubygems"
require "erb"
require "optparse"

# TODO(sissel): Currently this doc generator doesn't follow ancestry, so
# LogStash::Input::Amqp inherits Base, but we don't parse the base file.
# We need this, though.

$: << Dir.pwd
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

  def generate(file, settings)
    require "logstash/inputs/base"
    require "logstash/filters/base"
    require "logstash/outputs/base"
    string = File.new(file).read
    parse(string)
    require file
    puts "Generating docs for #{file}"

    if @name.nil?
      $stderr.puts "Missing 'config_name' setting in #{file}?"
      return nil
    end

    klass = LogStash::Config::Registry.registry[@name]
    if klass.ancestors.include?(LogStash::Inputs::Base)
      section = "inputs"
    elsif klass.ancestors.include?(LogStash::Filters::Base)
      section = "filters"
    elsif klass.ancestors.include?(LogStash::Outputs::Base)
      section = "outputs"
    end

    template_file = File.join(File.dirname(__FILE__), "docs.markdown.erb")
    template = ERB.new(File.new(template_file).read, nil, "-")

    sorted_settings = @settings.sort { |a,b| a.first.to_s <=> b.first.to_s }
    klassname = LogStash::Config::Registry.registry[@name].to_s
    name = @name

    if settings[:output]
      dir = File.join(settings[:output], section)
      path = File.join(dir, "#{name}.markdown")
      Dir.mkdir(settings[:output]) if !File.directory?(settings[:output])
      Dir.mkdir(dir) if !File.directory?(dir)
      File.open(path, "w") do |out|
        out.puts(template.result(binding))
      end
    else 
      puts template.result(binding)
    end
  end # def generate

  def foo(file)
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
      required = config[:required] ? " (*REQUIRED*)" : ""
      if name.is_a?(Regexp)
        puts "## /#{name}/ #{required}"
      else
        puts "## #{name} #{required}"
      end
      puts
      puts "* Value type is #{config[:validate] or "string"}"
      puts "* Default is #{config[:default].inspect}" if config.include?(:default)
      puts
      puts config[:description]
      puts 
    end
  end # def generate
end # class LogStashConfigDocGenerator

if __FILE__ == $0
  opts = OptionParser.new
  settings = {}
  opts.on("-o DIR", "--output DIR", 
          "Directory to output to; optional. If not specified,"\
          "we write to stdout.") do |val|
    settings[:output] = val
  end

  args = opts.parse(ARGV)

  args.each do |arg|
    gen = LogStashConfigDocGenerator.new
    gen.generate(arg, settings)
  end
end
