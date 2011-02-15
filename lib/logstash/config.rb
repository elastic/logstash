
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
    base.extend(ClassMethods)
  end

  module ClassMethods
    def section(name)
      @section = name
    end # def self.section

    def config(cfg)
      # cfg should be hash with one entry of { "key" => "val" }
      key, value = cfg.to_a.first
      puts "#{@section} {"
      puts "  #{key} => #{value}"
      puts "}"
    end # def self.config
  end # module ClassMethods
end # module LogStash::Config
