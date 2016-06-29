# encoding: utf-8
require "open3"
require "bundler"

module LogStash
  class CommandExecutor
    class CommandError < StandardError; end

    class CommandResponse
      attr_reader :stdin, :stdout, :stderr, :exitstatus

      def initialize(stdin, stdout, stderr, exitstatus)
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr
        @exitstatus = exitstatus
      end

      def success?
        exitstatus == 0
      end
    end

    def self.run(cmd, debug=false)
      # This block is require to be able to launch a ruby subprocess
      # that use bundler.
      Bundler.with_clean_env do
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
        stdout_acc, stderr_acc = "", ""
        stdout_reporter = reporter(stdout, wait_thr) do |c|
          stdout_acc << c
          print c if debug
        end
        reporter(stderr, wait_thr) do |c|
          stderr_acc << c;
          print c if debug
        end
        stdout_reporter.join
        CommandResponse.new(stdin, stdout_acc, stderr_acc, wait_thr.value.exitstatus)
      end
    end

    # This method will raise an exception if the `CMD`
    # was not run successfully and will display the content of STDERR
    def self.run!(cmd, debug=false)
      response = run(cmd, debug)

      unless response.success?
        raise CommandError, "CMD: #{cmd} STDERR: #{response.stderr}"
      end
      response
    end

    private

    def self.reporter(io, wait_thr, &block)
      Thread.new(io, wait_thr) do |_io, _wait_thr|
        while (_wait_thr.status == "run")
          begin
            c = _io.read(1)
            block.call(c) if c
          rescue IO::WaitReadable
            IO.select([_io])
            retry
          end
        end
      end
    end

  end
end
