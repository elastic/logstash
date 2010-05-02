require 'rubygems'
require 'yaml'

module LogStash; module Config
  # Base config class. All configs need to know how to get to a broker.

  class BaseConfig
    attr_reader :elasticsearch_host
    def initialize(file)
      obj = YAML::load(::File.open(file).read())
      @elasticsearch_host = obj["elasticsearch_host"] || "localhost:9200"

      @mqhost = obj["mqhost"] || "localhost"
      @mqport = obj["mqport"] || 5672
      @mquser = obj["mquser"] || "guest"
      @mqpass = obj["mqpass"] || "guest"
      @mqvhost = obj["mqvhost"] || "/"
      @mqexchange = "logstash.topic"
    end # def initialize
  end # class BaseConfig
end; end # module LogStash::Config
