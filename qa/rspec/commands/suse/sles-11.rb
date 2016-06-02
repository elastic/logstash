# encoding: utf-8
require_relative "../base"
require_relative "../suse"

module ServiceTester
  class Sles11Commands < SuseCommands

    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("/etc/init.d/#{package} status")
        stdout = cmd.stdout
      end
      stdout.match(/#{package} is running$/)
    end

    def service_manager(service, action, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("/etc/init.d/#{service} #{action}")
      end
    end

  end
end
