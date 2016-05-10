# encoding: utf-8
require "json"
require "open3"
require "open-uri"
require "stud/temporary"
require "fileutils"
require "bundler"
require "gems"

class CommandResponse
  attr_reader :stdin, :stdout, :stderr, :exit_status

  def initialize(cmd, stdin, stdout, stderr, exit_status)
    @stdin = stdin
    @stdout = stdout
    @stderr = stderr
    @exit_status = exit_status
    @cmd = cmd
  end

  def to_debug
    "DEBUG: stdout: #{stdout}, stderr: #{stderr}, exit_status: #{exit_status}"
  end

  def to_s
    @cmd
  end
end

def command(cmd, path = nil)
  # http://bundler.io/v1.3/man/bundle-exec.1.html
  # see shelling out.
  #
  # Since most of the integration test are environment destructive
  # its better to run them in a cloned directory.
  path = LOGSTASH_TEST_PATH if path == nil

  Bundler.with_clean_env do
    Dir.chdir(path) do
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          CommandResponse.new(cmd,
            stdin,
            stdout.read.chomp,
            stderr.read.chomp,
            wait_thr.value.exitstatus)
      end
    end
  end
end

def gem_fetch(name)
  tmp = Stud::Temporary.directory
  FileUtils.mkdir_p(tmp)

  c = command("gem fetch #{name}", tmp)

  if c.exit_status == 1
    raise RuntimeError, "Can't fetch gem #{name}"
  end

  return Dir.glob(File.join(tmp, "#{name}*.gem")).first
end

# This is a bit hacky since JRuby doesn't support fork,
# we use popen4 which return the pid of the process and make sure we kill it
# after letting it run for a few seconds.
def launch_logstash(cmd, path = nil)
  path = LOGSTASH_TEST_PATH if path == nil
  pid = 0

  Thread.new do
    Bundler.with_clean_env do
      Dir.chdir(path) do
        pid, input, output, error = IO.popen4(cmd) #jruby only
      end
    end
  end
  sleep(30)
  begin
    Process.kill("INT", pid)
  rescue
  end
end

module LogStashTestHelpers
  def self.latest_version(name)
    Gems.versions(name).first["number"] 
  end
end
