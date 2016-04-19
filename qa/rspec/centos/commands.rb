# encoding: utf-8
module ServiceTester
  class CentosCommands

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = exec!("yum list installed  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Installed Packages$/)
      stdout.match(/^logstash.noarch/)
    end

    def install(package, host=nil)
      hosts  = (host.nil? ? servers : Array(host))
      errors = {}
      at(hosts, {in: :serial}) do |_host|
        cmd = sudo_exec!("yum install -y  #{package}")
        errors[_host] = cmd.stderr unless cmd.stderr.empty?
      end
      errors
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
      at(hosts, {in: :serial}) do |host|
        sudo_exec!("service #{service} #{action}")
      end
    end

  end
end
