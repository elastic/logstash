# encoding: utf-8
require_relative "base"

module ServiceTester
  class DebianCommands < Base

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
    end

    def package_for(version)
      File.join(ServiceTester::Base::LOCATION, "logstash-#{version}_all.deb")
    end

    def install(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("dpkg -i  #{package}")
      end
    end

    def uninstall(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("dpkg -r #{package}")
        sudo_exec!("dpkg --purge #{package}")
      end
    end

    def removed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s #{package}")
        stdout = cmd.stderr
      end
      (
        stdout.match(/^Package `#{package}' is not installed and no info is available.$/) ||
        stdout.match(/^dpkg-query: package '#{package}' is not installed and no information is available$/)
      )
    end

    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("service #{package} status")
        stdout = cmd.stdout
      end
      stdout.match(/^#{package} is running$/)
    end

    def service_manager(service, action, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("service #{service} #{action}")
      end
    end

  end
end
