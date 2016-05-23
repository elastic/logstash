# encoding: utf-8
require_relative "../base"
require_relative "../redhat"

module ServiceTester
  class Centos6Commands < RedhatCommands
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
        sudo_exec!("initctl #{service} #{action}")
      end
    end
  end
end
