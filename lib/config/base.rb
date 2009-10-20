require 'yaml'

module LogStash; module Config
  # Base config class. All configs need to know how to get to a broker.
  class BaseConfig
    attr_reader :mqhost
    attr_reader :mqport
    attr_reader :mquser
    attr_reader :mqpass
    attr_reader :mqvhost

    def initialize(file)
      obj = YAML::load(File.open(file).read())

      @mqhost = obj["mqhost"] || "localhost"
      @mqport = obj["mqport"] || 5672
      @mquser = obj["mquser"] || "guest"
      @mqpass = obj["mqpass"] || "guest"
      @mqvhost = obj["mqvhost"] || "/"
    end # def initialize
  end # class BaseConfig
end; end # module LogStash::Config
