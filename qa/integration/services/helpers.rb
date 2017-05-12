# encoding: utf-8
require 'childprocess'
require 'stud/temporary'
require 'open-uri'
require 'ruby-progressbar'
require 'zlib'
require 'rubygems/package'

# Spawn a command that run in background.
class BackgroundProcess
  def initialize(cmd)
    @client_out = Stud::Temporary.file
    @client_out.sync

    @process = ChildProcess.build(*cmd)
    @process.duplex = true
    @process.io.stdout = @process.io.stderr = @client_out
    ChildProcess.posix_spawn = true
  end

  def start
    @process.start
    sleep(0.1)
    self
  end

  def execution_output
    @client_out.rewind

    # can be used to helper debugging when a test fails
    @execution_output = @client_out.read
  end

  def stop
    begin
      @process.poll_for_exit(5)
    rescue ChildProcess::TimeoutError
      Process.kill("KILL", @process.pid)
    end
  end
end

# Download tarball to install directory.
def download (url, to_dir, to_name)
  dst = File.join(to_dir, to_name)
  pb = nil
  puts "Downloading #{url} to #{dst}."
  open(url,
    :content_length_proc => lambda {|l|
      pb = ProgressBar.create(:total => l) if l
    },
    :progress_proc => lambda {|s|
      pb.progress = s if pb
    }) do |io|
      File.open(dst, "wb") do |f|
        IO.copy_stream(io, f)
      end
  end
  puts "Download complete."
  dst
end

# Unpack a TAR Gzip file.
def untgz (tgz, dst_dir, options = {})
  options[:strip_path] ||= 0
  fs = File::SEPARATOR
  FileUtils.mkdir_p (dst_dir)
  puts "Extracting #{tgz} in #{dst_dir}."
  File.open(tgz, "rb") do |file|
    Zlib::GzipReader.open(file) do |gz|
      Gem::Package::TarReader.new(gz).each_entry do |entry|
        entry_new_name = entry.full_name.split(fs).slice(options[:strip_path]..-1).join(fs)
        if entry.directory?
          FileUtils.mkdir_p(File.join(dst_dir, entry_new_name))
        else
          File.open(File.join(dst_dir, entry_new_name), "wb", entry.header.mode) do |fe|
            fe.write(entry.read)
          end
        end
      end
    end
  end
  puts "Extract complete."
end
