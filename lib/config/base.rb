require 'rubygems'
require 'mqrpc'
require 'yaml'

module LogStash; module Config
  # Base config class. All configs need to know how to get to a broker.
  class BaseConfig < MQRPC::Config
    def initialize(file)
      obj = YAML::load(File.open(file).read())
      @mqhost = obj["mqhost"] || "localhost"
      @mqport = obj["mqport"] || 5672
      @mquser = obj["mquser"] || "guest"
      @mqpass = obj["mqpass"] || "guest"
      @mqvhost = obj["mqvhost"] || "/"
      @mqexchange = "logstash.topic"
    end # def initialize
  end # class BaseConfig
end; end # module LogStash::Config
