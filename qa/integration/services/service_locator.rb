# encoding: utf-8
require_relative "service"

# This is a registry used in Fixtures so a test can get back any service class
# at runtime
# All new services should register here
class ServiceLocator
  FILE_PATTERN = "_service.rb"

  def initialize(settings)
    @services = {}
    available_services do |name, klass|
      @services[name] = klass.new(settings)
    end
  end

  def get_service(name)
    @services.fetch(name)
  end

  def available_services
    Dir.glob(File.join(File.dirname(__FILE__), "*#{FILE_PATTERN}")).each do |f|
      require f
      basename = File.basename(f).gsub(/#{FILE_PATTERN}$/, "")
      service_name = basename.downcase
      klass = Object.const_get("#{service_name.capitalize}Service")
      yield service_name, klass
    end
  end
end
