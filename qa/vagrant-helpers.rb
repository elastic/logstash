# encoding: utf-8
require "open3"
require "json"

module LogStash
  class VagrantHelpers
    DEFAULT_CENTOS_BOXES = [ "centos-6", "centos-7" ]
    DEFAULT_DEBIAN_BOXES = [ "ubuntu-1204", "ubuntu-1404"]

    def self.bootstrap(box)
      Dir.chdir("acceptance") do
        p execute("vagrant up #{box} --provider virtualbox")
        raw_ssh_config    = execute("vagrant ssh-config")[:stdout].split("\n");
        parsed_ssh_config = parse(raw_ssh_config)
        File.write(".vm_ssh_config", parsed_ssh_config.to_json)
      end
    end

    def self.destroy(box)
      Dir.chdir("acceptance") do
        execute("vagrant destroy #{box} -f")
        File.delete(".vm_ssh_config")
      end
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
