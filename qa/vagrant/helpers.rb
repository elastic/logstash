# encoding: utf-8
require "open3"
require "bundler"
require_relative "command"

module LogStash
  class VagrantHelpers

    def self.halt(machines="")
      CommandExecutor.run!("vagrant halt #{machines.join(' ')}")
    end

    def self.destroy(machines="")
      CommandExecutor.run!("vagrant destroy --force #{machines.join(' ')}") 
    end

    def self.bootstrap(machines="")
      CommandExecutor.run!("vagrant up #{machines.join(' ')}")
    end

    def self.save_snapshot(machine="")
      CommandExecutor.run!("vagrant snapshot save #{machine} #{machine}-snapshot")
    end

    def self.restore_snapshot(machine="")
      CommandExecutor.run!("vagrant snapshot restore #{machine} #{machine}-snapshot")
    end

    def self.fetch_config
      machines = CommandExecutor.run!("vagrant status").stdout.split("\n").select { |l| l.include?("running") }.map { |r| r.split(' ')[0]}
      CommandExecutor.run!("vagrant ssh-config #{machines.join(' ')}")
    end

    def self.parse(lines)
      hosts, host = [], {}
      lines.each do |line|
        if line.match(/Host\s(.*)$/)
          host = { :host => line.gsub("Host","").strip }
        elsif line.match(/HostName\s(.*)$/)
          host[:hostname] = line.gsub("HostName","").strip
        elsif line.match(/Port\s(.*)$/)
          host[:port]     = line.gsub("Port","").strip
        elsif line.empty?
          hosts << host
          host = {}
        end
      end
      hosts << host
      hosts
    end
  end
end
