# encoding: utf-8
require_relative "base"

module ServiceTester
  class RedhatCommands < Base

    include ::ServiceTester::SystemD

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = exec!("yum list installed  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Installed Packages$/)
      stdout.match(/^logstash.noarch/)
    end

    def package_for(filename, base=ServiceTester::Base::LOCATION)
      File.join(base, "#{filename}.rpm")
    end

    def install(package, host=nil)
      hosts  = (host.nil? ? servers : Array(host))
      errors = []
      exit_status = 0
      at(hosts, {in: :serial}) do |_host|
        cmd = sudo_exec!("yum install -y  #{package}")
        exit_status += cmd.exit_status
        errors << cmd.stderr unless cmd.stderr.empty?
      end
      if exit_status > 0 
        raise InstallException.new(errors.join("\n"))
      end
    end

    def uninstall(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("yum remove -y #{package}")
      end
    end

    def removed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("yum list installed #{package}")
        stdout = cmd.stderr
      end
      stdout.match(/^Error: No matching Packages to list$/)
    end
  end
end
