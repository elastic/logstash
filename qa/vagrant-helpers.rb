# encoding: utf-8
require "open3"

module LogStash
  class VagrantHelpers
    class CommandError < StandardError; end

    class ExecuteResponse
      attr_reader :stdin, :stdout, :stderr, :exitstatus

      def initialize(stdin, stdout, stderr, exitstatus)
        @stdin = stdin, 
        @stdout = stdout
        @stderr = stderr
        @exitstatus = exitstatus
      end

      def success?
        exitstatus == 0
      end
    end

    def self.bootstrap
      execute_successfully("vagrant up")
    end

    def self.fetch_config
      execute_successfully("vagrant ssh-config")
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
        ExecuteResponse.new(stdin, stdout.read.chomp, stderr.read.chomp, wait_thr.value.exitstatus)
      end
    end

    def self.execute_successfully(cmd)
      response = execute(cmd)
    
      unless response.success?
        raise CommandError, "CMD: #{cmd} STDERR: #{response.stderr}"
      end
      response
    end
  end
end
