# encoding: utf-8
require_relative "base"

module ServiceTester
  class DebianCommands < Base

    include ::ServiceTester::SystemD

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
    end

    def package_for(filename, base=ServiceTester::Base::LOCATION)
      File.join(base, "#{filename}.deb")
    end

    def install(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      errors = []
      at(hosts, {in: :serial}) do |_|
        cmd = sudo_exec!("dpkg -i --force-confnew #{package}")
        if cmd.exit_status != 0
          errors << cmd.stderr.to_s
        end
      end
      raise InstallException.new(errors.join("\n")) unless errors.empty?
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
  end
end
