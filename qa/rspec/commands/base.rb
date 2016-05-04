# encoding: utf-8
require_relative "../../vagrant/helpers"

module ServiceTester

  class Base

    LOCATION="/logstash-build".freeze

    def snapshot(host)
      LogStash::VagrantHelpers.save_snapshot(host)
    end

    def restore(host)
      LogStash::VagrantHelpers.restore_snapshot(host)
    end

    def start_service(service, host=nil)
      service_manager(service, "start", host)
    end

    def stop_service(service, host=nil)
      service_manager(service, "stop", host)
    end

  end
end
