require_relative "base"

module ServiceTester
  module SystemD
    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("service #{package} status")
        stdout = cmd.stdout
      end
      (
        stdout.match(/Active: active \(running\)/) &&
        stdout.match(/#{package}.service - #{package}/)
      )
    end

    def service_manager(service, action, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("service #{service} #{action}")
      end
    end
  end

  module InitD
    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("initctl status #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/#{package} start\/running/)
    end

    def service_manager(service, action, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("initctl #{action} #{service}")
      end
    end 
  end
end
