require 'rubygems'
#require 'lib/util'

module LogStash

  class Program
    class PidFileLockFailed < StandardError
    end # class LogStash::Program::PidFileLockFailed 

    def initialize(options)
      @pidfile = options[:pidfile]
      @logfile = options[:logfile]
      @daemonize = options[:daemonize]
      @options = options
      @dying = false
    end

    def run
      Thread::abort_on_exception = true
      redirect_io
      daemonize if @daemonize
      grab_pidfile if @pidfile
      termination_handler do
        puts "Default termination signal handler being invoked."
      end
      yield @options if block_given?
    end # def run

    def termination_handler(&block)
      puts "Block: #{block.inspect}"
      puts "Block: #{block.inspect}"
      puts "Block: #{block.inspect}"
      puts "Block: #{block.inspect}"
      puts "Block: #{block.inspect}"

      @termination_callback = block
      Signal.trap("INT") do
        Process.kill("TERM", $$)
      end

      Signal.trap("TERM") do
        dying
        $logger.warn "received SIGTERM, shutting down"
        @termination_handler.call if @termination_handler
        Process.waitall
        if @pidfile_fd
          @pidfile_fd.close
          @pidfile_fd.delete
        end
        exit(5)
      end
    end # def register_signals

    def redirect_io
      if @logfile != nil
        logfd = File.open(@logfile, "a")
        logfd.sync = true
        $stdout.reopen(logfd)
        $stderr.reopen(logfd)
      else
        # Require a logfile for daemonization
        if @daemonize
          $stderr.puts "Daemonizing requires you specify a logfile"
          return 1
        end
      end
    end # def redirect_io

    def grab_pidfile
      if @pidfile
        pidfile = File.open(@pidfile, IO::RDWR | IO::CREAT)
        gotlock = pidfile.flock(File::LOCK_EX | File::LOCK_NB)
        if !gotlock
          owner = pidfile.read()
          if owner.length == 0
            owner = "unknown"
          end
          $stderr.puts "Failed to get lock on #{@pidfile}; owned by #{owner}"
          raise LogStash::Program::PidFileLockFailed(@pidfile)
        end
        pidfile.truncate(0)
        pidfile.puts $$
        pidfile.flush
        @pidfile_fd = pidfile
      end
    end # def grab_pidfile

    def daemonize
      fork and exit(0)

      # Copied mostly from  Daemons.daemonize, but since the ruby 1.8 'daemons'
      # and gem 'daemons' have api variances, let's do it ourselves since nobody
      # agrees.
      trap("SIGHUP", "IGNORE")
      Process.setsid
      ObjectSpace.each_object(IO) do |io|
        # closing STDIN is ok, but keep STDOUT and STDERR
        # close everything else
        next if [$stdout, $stdout].include?(io)
        begin
          unless io.closed?
            io.close
          end
        rescue ::Exception
        end
      end
    end # def daemonize

    def dying
      @dying = true
    end

    def dying?
      return @dying
    end
  end # class LogStash::Program
end # class LogStash
