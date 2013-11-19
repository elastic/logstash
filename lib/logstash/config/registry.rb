# encoding: utf-8
require "logstash/namespace"

# Global config registry.
module LogStash::Config::Registry
  @registry = Hash.new
  class << self
    attr_accessor :registry

    # TODO(sissel): Add some helper methods here.
  end
end # module LogStash::Config::Registry
  
