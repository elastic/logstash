# encoding: utf-8
require "open3"
require "bundler"

module LogStash
  class CommandExecutor
    class CommandError < StandardError; end

    class CommandResponse
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

    def self.run(cmd)
      # This block is require to be able to launch a ruby subprocess
      # that use bundler.
      Bundler.with_clean_env do
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          CommandResponse.new(stdin, stdout.read.chomp, stderr.read.chomp, wait_thr.value.exitstatus)
        end
      end
    end

    # This method will raise an exception if the `CMD`
    # was not run successfully and will display the content of STDERR
    def self.run!(cmd)
      response = run(cmd)
    
      unless response.success?
        raise CommandError, "CMD: #{cmd} STDERR: #{response.stderr}"
      end
      response
    end
  end

  class VagrantHelpers

    def self.bootstrap
      CommandExecutor.run!("vagrant up")
    end

    def self.fetch_config
      CommandExecutor.run!("vagrant ssh-config")
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
