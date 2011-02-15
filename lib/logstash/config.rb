
require "logstash/namespace"

# This module is meant as a mixin to classes wishing to be configurable from
# config files
#
# The idea is that you can do this:
#
# class Foo < LogStash::Config
#   config "path" => ...
#   config "tag" => ...
# end
#
# And the config file should let you do:
#
# foo {
#   "path" => ...
#   "tag" => ...
# }
#
# TODO(sissel): This is not yet fully designed.
module LogStash::Config
  # This method is called when someone does 'include LogStash::Config'
  def self.included(base)
    # Add ClassMethods module methods to the 'base' given.
    base.extend(LogStash::Config::DSL)
  end

  module DSL
    attr_accessor :dsl_name
    attr_accessor :dsl_parent

    # Set the parent config for this class.
    def dsl_parent(*args)
      @dsl_parent = args[0] if args.length > 0
      return @dsl_parent
    end

    # Set the config name for this class.
    def dsl_name(*args)
      @dsl_name = args[0] if args.length > 0
      return @dsl_name
    end

    def dsl_config(cfg)
      # cfg should be hash with one entry of { "key" => "val" }
      @dsl_config ||= Hash.new
      key, value = cfg.to_a.first
      @dsl_config[key] = value
    end # def config

    def dsl_gen
      puts "#{@dsl_parent.dsl_name} { #parent" if @dsl_parent
      config = []
      config << "#{@dsl_name} { #node"
      config << "  \"somename\":"
      attrs = []
      (@dsl_config || Hash.new).each do |key, value|
        attrs << "    #{key} => #{value},"
      end
      config += attrs
      config << "} #node"
      config = config.collect { |p| "#{@dsl_parent.nil? ? "" : "  "}#{p}" }
      puts config.join("\n")
      puts "} #parent" if @dsl_parent
    end

    def inherited(subclass)
      # Copy our parent's config to a subclass.
      # This method is invoked whenever someone subclasses us, like:
      # class Foo < Bar ...
      config = Hash.new
      @dsl_config.each do |key, val|
        #puts "#{self}: Sharing config '#{key}' with subclass #{subclass}"
        config[key] = val
      end
      subclass.instance_variable_set("@dsl_config", config)
      subclass.dsl_parent = self
    end # def inherited
  end # module LogStash::Config::DSL
end # module LogStash::Config
