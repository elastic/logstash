# encoding: utf-8
require_relative "debian"

module ServiceTester
  class UbuntuCommands < DebianCommands

    def running?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("service #{package} status")
        stdout = cmd.stdout
      end
      stdout.match(/^#{package} start\/running/)
    end

  end
end
