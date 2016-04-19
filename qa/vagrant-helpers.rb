# encoding: utf-8
require "open3"

module LogStash
  class VagrantHelpers

    def self.bootstrap
      execute("vagrant up")
    end

    def self.fetch_config
      execute("vagrant ssh-config")
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

    private

    def self.execute(cmd)
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        { :stdout => stdout.read.chomp, :stderr => stderr.read.chomp,
          :exit_status => wait_thr.value.exitstatus }
      end
    end

  end
end
