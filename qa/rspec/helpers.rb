# encoding: utf-8
require_relative "commands"

module ServiceTester

  class Configuration
    attr_accessor :servers, :lookup
    def initialize
      @servers  = []
      @lookup   = {}
    end

    def hosts
      lookup.values.map { |val| val["host"] }
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def servers
    ServiceTester.configuration.servers
  end

  def package_for(type, version)
     package_name = "/logstash-build/logstash-#{LOGSTASH_VERSION}"
     if type == "debian"
       package_name = "#{package_name}_all.deb"
     elsif type == "redhat"
       package_name = "#{package_name}.noarch.rpm"
     else
       raise Exception.new("Unknown package type=#{type}")
     end
     package_name
  end

  def install(package, host=nil)
    select_client.install(package, host)
  end

  def uninstall(package, host=nil)
    select_client.uninstall(package, host)
  end

  def start_service(service, host=nil)
    select_client.service_manager(service, "start", host)
  end

  def stop_service(service, host=nil)
    select_client.service_manager(service, "stop", host)
  end

  def select_client
    CommandsFactory.fetch(current_example.metadata[:platform])
  end

  def current_example
    RSpec.respond_to?(:current_example) ? RSpec.current_example : self.example
  end
end
