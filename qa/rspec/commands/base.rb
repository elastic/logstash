# encoding: utf-8

module ServiceTester

  class Base

    LOCATION="/logstash-build".freeze

    def start_service(service, host=nil)
      service_manager(service, "start", host)
    end

    def stop_service(service, host=nil)
      service_manager(service, "stop", host)
    end

  end
end
