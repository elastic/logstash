# encoding: utf-8
require_relative "base"

module ServiceTester
  class SuseCommands < Base

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = exec!("zypper search #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^i | logstash | An extensible logging pipeline | package$/)
    end

    def package_for(filename, base=ServiceTester::Base::LOCATION)
      File.join(base, "#{filename}.rpm")
    end

    def install(package, host=nil)
      hosts  = (host.nil? ? servers : Array(host))
      errors = []
      at(hosts, {in: :serial}) do |_host|
        cmd = sudo_exec!("zypper --no-gpg-checks --non-interactive install  #{package}")
        errors << cmd.stderr unless cmd.stderr.empty?
      end
      raise InstallException.new(errors.join("\n")) unless errors.empty?
    end

    def uninstall(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        cmd = sudo_exec!("zypper --no-gpg-checks --non-interactive remove #{package}")
      end
    end

    def removed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd    = exec!("zypper search #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/No packages found/)
    end

    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("service #{package} status")
        stdout = cmd.stdout
      end
      stdout.match(/Active: active \(running\)/)
    end

    def service_manager(service, action, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("service #{service} #{action}")
      end
    end

  end
end
