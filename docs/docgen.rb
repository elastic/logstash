require "rubygems"
require "erb"
require "optparse"
require "bluecloth" # for markdown parsing

$: << Dir.pwd
$: << File.join(File.dirname(__FILE__), "..", "lib")

require "logstash/config/mixin"
require "logstash/inputs/base"
require "logstash/filters/base"
require "logstash/outputs/base"
require "logstash/version"

class LogStashConfigDocGenerator
  COMMENT_RE = /^ *#(?: (.*)| *$)/

  def initialize
    @rules = {
      COMMENT_RE => lambda { |m| add_comment(m[1]) },
      /^ *class.*< *LogStash::(Outputs|Filters|Inputs)::Base/ => \
        lambda { |m| set_class_description },
      /^ *config +[^=].*/ => lambda { |m| add_config(m[0]) },
      /^ *plugin_status .*/ => lambda { |m| set_plugin_status(m[0]) },
      /^ *config_name .*/ => lambda { |m| set_config_name(m[0]) },
      /^ *flag[( ].*/ => lambda { |m| add_flag(m[0]) },
      /^ *(class|def|module) / => lambda { |m| clear_comments },
    }
  end

  def parse(string)
    clear_comments
    buffer = ""
    string.split(/\r\n|\n/).each do |line|
      # Join long lines
      if line =~ COMMENT_RE
        # nothing
      else
        # Join extended lines
        if line =~ /(, *$)|(\\$)|(\[ *$)/
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

  def set_class_description
    @class_description = @comments.join("\n")
    clear_comments
  end # def set_class_description
 
  def add_comment(comment)
    @comments << comment
  end # def add_comment

  def add_config(code)
    # I just care about the 'config :name' part
    code = code.sub(/,.*/, "")

    # call the code, which calls 'config' in this class.
    # This will let us align comments with config options.
    name, opts = eval(code)

    description = BlueCloth.new(@comments.join("\n")).to_html
    @attributes[name][:description] = description
    clear_comments
  end # def add_config

  def add_flag(code)
    # call the code, which calls 'config' in this class.
    # This will let us align comments with config options.
    #p :code => code
    fixed_code = code.gsub(/ do .*/, "")
    #p :fixedcode => fixed_code
    name, description = eval(fixed_code)
    @flags[name] = description
    clear_comments
  end # def add_flag

  def set_config_name(code)
    name = eval(code)
    @name = name
  end # def set_config_name

  def set_plugin_status(code)
    status = eval(code)
    @plugin_status = status
  end

  # pretend to be the config DSL and just get the name
  def config(name, opts={})
    return name, opts
  end # def config

  # Pretend to support the flag DSL
  def flag(*args, &block)
    name = args.first
    description = args.last
    return name, description
  end # def config

  # pretend to be the config dsl's 'config_name' method
  def config_name(name)
    return name
  end # def config_name

  # pretend to be the config dsl's 'plugin_status' method
  def plugin_status(status)
    return status
  end # def plugin_status

  def clear_comments
    @comments.clear
  end # def clear_comments

  def generate(file, settings)
    @class_description = ""
    @plugin_status = ""
    @comments = []
    @attributes = Hash.new { |h,k| h[k] = {} }
    @flags = {}

    # local scoping for the monkeypatch belowg
    attributes = @attributes
    # Monkeypatch the 'config' method to capture
    # Note, this monkeypatch requires us do the config processing
    # one at a time.
    #LogStash::Config::Mixin::DSL.instance_eval do
      #define_method(:config) do |name, opts={}|
        #p name => opts
        #attributes[name].merge!(opts)
      #end
    #end

    # Loading the file will trigger the config dsl which should
    # collect all the config settings.
    load file

    # parse base first
    parse(File.new(File.join(File.dirname(file), "base.rb"), "r").read)

    # Now parse the real library
    code = File.new(file).read

    # inputs either inherit from Base or Threadable.
    if code =~ /\< LogStash::Inputs::Threadable/
      parse(File.new(File.join(File.dirname(file), "threadable.rb"), "r").read)
    end

    parse(code)

    puts "Generating docs for #{file}"

    if @name.nil?
      $stderr.puts "Missing 'config_name' setting in #{file}?"
      return nil
    end

    klass = LogStash::Config::Registry.registry[@name]
    if klass.ancestors.include?(LogStash::Inputs::Base)
      section = "input"
    elsif klass.ancestors.include?(LogStash::Filters::Base)
      section = "filter"
    elsif klass.ancestors.include?(LogStash::Outputs::Base)
      section = "output"
    end

    template_file = File.join(File.dirname(__FILE__), "plugin-doc.html.erb")
    template = ERB.new(File.new(template_file).read, nil, "-")

    # descriptions are assumed to be markdown
    description = BlueCloth.new(@class_description).to_html

    @attributes = klass.get_config
    sorted_attributes = @attributes.sort { |a,b| a.first.to_s <=> b.first.to_s }
    klassname = LogStash::Config::Registry.registry[@name].to_s
    name = @name

    if settings[:output]
      dir = File.join(settings[:output], section + "s")
      path = File.join(dir, "#{name}.html")
      Dir.mkdir(settings[:output]) if !File.directory?(settings[:output])
      Dir.mkdir(dir) if !File.directory?(dir)
      File.open(path, "w") do |out|
        html = template.result(binding)
        html.gsub!("%VERSION%", LOGSTASH_VERSION)
        out.puts(html)
      end
    else 
      puts template.result(binding)
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
