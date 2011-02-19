
require "logstash/namespace"
require "logstash/config/registry"

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
module LogStash::Config::Mixin
  # This method is called when someone does 'include LogStash::Config'
  def self.included(base)
    puts "Configurable class #{base.name}"
    #
    # Add the DSL methods to the 'base' given.
    base.extend(LogStash::Config::Mixin::DSL)
  end

  module DSL
    # If name is given, set the name and return it.
    # If no name given (nil), return the current name.
    def config_name(name=nil)
      @config_name = name if !name.nil?
      LogStash::Config::Registry.registry[name] = self
      return @config_name
    end

    # If config is given, add this config.
    # If no config given (nil), return the current config hash
    def config(cfg=nil)
      # cfg should be hash with one entry of { "key" => "val" }
      @config ||= Hash.new
      key, value = cfg.to_a.first
      @config[key] = value
      return @config
    end # def config

    def dsl_gen
      puts "#{@dsl_parent.config_name} { #parent" if @dsl_parent
      config = []
      config << "#{@config_name} { #node"
      config << "  \"somename\":"
      attrs = []
      (@config || Hash.new).each do |key, value|
        attrs << "    #{key} => #{value},"
      end
      config += attrs
      config << "} #node"
      config = config.collect { |p| "#{@dsl_parent.nil? ? "" : "  "}#{p}" }
      puts config.join("\n")
      puts "} #parent" if @dsl_parent
    end

    # This is called whenever someone subclasses a class that has this mixin.
    def inherited(subclass)
      # Copy our parent's config to a subclass.
      # This method is invoked whenever someone subclasses us, like:
      # class Foo < Bar ...
      subconfig = Hash.new
      if !@config.nil?
        @config.each do |key, val|
          puts "#{self}: Sharing config '#{key}' with subclass #{subclass}"
          subconfig[key] = val
        end
      end
      subclass.instance_variable_set("@config", subconfig)
    end # def inherited
  end # module LogStash::Config::DSL
end # module LogStash::Config
