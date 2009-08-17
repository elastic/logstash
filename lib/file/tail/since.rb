require 'rubygems'
require 'file/tail'
require 'yaml'

class File; module Tail; 

  class SinceState
    attr_reader :inode
    attr_reader :pos
    attr_reader :mtime
    attr_reader :dev 

    def update(file)
      @pos = file.pos
      stat = file.stat

      @inode = stat.ino
      @mtime = stat.mtime.to_i
      @dev = stat.dev
    end
  end

  class Since < File::Tail::Logfile
    attr_accessor :statefile

    def initialize(*args)
      @statefile = "#{ENV["HOME"]}/.rb_since"
      super(*args)
      load_state
    end

    def tail(n = nil, &block)
      super(n) do |*args|
        yield *args
        save_state
      end
    end

    def lock_state(fd, &block)
      fd.flock(File::LOCK_EX)
      yield
      fd.flock(File::LOCK_UN)
    end

    def load_state
      if !File.exist?(@statefile)
        return Hash.new
      end

      statefd = File.open(@statefile, "r");
      lock_state(statefd) do
        data = (YAML::load(statefd.read()) or Hash.new)
        if data.has_key?(path)
          state = data[path]
          fstat = stat
          if fstat.ino == state.inode && fstat.dev == state.dev
            #$stdout.puts "Seek to #{state.pos}"
            seek(state.pos, File::SEEK_SET)
          end
        end
      end
      statefd.close
    end

    def save_state
      statefd = File.open(@statefile, "w+");
      lock_state(statefd) do
        # TODO(sissel): We should catch load/read exceptions
        data = (YAML::load(statefd.read()) or Hash.new)
        if !data.has_key?(path)
          data[path] = SinceState.new
        end

        data[path].update(self)

        statefd.truncate(0)
        statefd.seek(0, File::SEEK_SET)
        statefd.write(data.to_yaml)
      end
      statefd.close()
    end
  end # class Since

end; end; # File::Tail

if $0 == __FILE__
  File::Tail::Since.new("/var/log/messages").tail do |line|
    puts line
  end
end
