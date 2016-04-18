namespace "vendor" do
  VERSIONS = {
    "jruby" => { "version" => "1.7.25", "sha1" => "cd15aef419f97cff274491e53fcfb8b88ec36785" },
  }

  def vendor(*args)
    return File.join("vendor", *args)
  end

  # Untar any files from the given tarball file name.
  #
  # A tar entry is passed to the block. The block should should return
  # * nil to skip this file
  # * or, the desired string filename to write the file to.
  def self.untar(tarball, &block)
    Rake::Task["dependency:archive-tar-minitar"].invoke
    require "archive/tar/minitar"
    tgz = Zlib::GzipReader.new(File.open(tarball,"rb"))
    tar = Archive::Tar::Minitar::Input.open(tgz)
    tar.each do |entry|
      path = block.call(entry)
      next if path.nil?
      parent = File.dirname(path)

      FileUtils.mkdir_p(parent) unless File.directory?(parent)

      # Skip this file if the output file is the same size
      if entry.directory?
        FileUtils.mkdir(path) unless File.directory?(path)
      else
        entry_mode = entry.instance_eval { @mode } & 0777
        if File.exists?(path)
          stat = File.stat(path)
          # TODO(sissel): Submit a patch to archive-tar-minitar upstream to
          # expose headers in the entry.
          entry_size = entry.instance_eval { @size }
          # If file sizes are same, skip writing.
          if Gem.win_platform?
            #Do not fight with windows permission scheme
            next if stat.size == entry_size
          else
            next if stat.size == entry_size && (stat.mode & 0777) == entry_mode
          end
        end
        puts "Extracting #{entry.full_name} from #{tarball} #{entry_mode.to_s(8)}" if ENV['DEBUG']
        File.open(path, "wb") do |fd|
          # eof? check lets us skip empty files. Necessary because the API provided by
          # Archive::Tar::Minitar::Reader::EntryStream only mostly acts like an
          # IO object. Something about empty files in this EntryStream causes
          # IO.copy_stream to throw "can't convert nil into String" on JRuby
          # TODO(sissel): File a bug about this.
          while !entry.eof?
            chunk = entry.read(16384)
            fd.write(chunk)
          end
        end
        File.chmod(entry_mode, path)
      end
    end
    tar.close
  end # def untar

  task "jruby" do |task, args|
    name = task.name.split(":")[1]
    info = VERSIONS[name]
    version = info["version"]

    discard_patterns = Regexp.union([
      /^samples/,
      /@LongLink/,
      /lib\/ruby\/1.8/,
      /lib\/ruby\/2.0/,
      /lib\/ruby\/shared\/rdoc/,
    ])

    url = "http://jruby.org.s3.amazonaws.com/downloads/#{version}/jruby-bin-#{version}.tar.gz"
    download = file_fetch(url, info["sha1"])

    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      next if parent =~ discard_patterns
      FileUtils.mkdir(parent)
    end.invoke unless Rake::Task.task_defined?(parent)

    prefix_re = /^#{Regexp.quote("jruby-#{version}/")}/
    untar(download) do |entry|
      out = entry.full_name.gsub(prefix_re, "")
      next if out =~ discard_patterns
      vendor(name, out)
    end # untar
  end # jruby

  task "all" => "jruby"

  task "system_gem", :jruby_bin, :name, :version do |task, args|
    jruby_bin = args[:jruby_bin]
    name = args[:name]
    version = args[:version]

    IO.popen([jruby_bin, "-S", "gem", "list", name, "--version", version, "--installed"], "r") do |io|
      io.readlines # ignore
    end
    unless $?.success?
      puts("Installing #{name} #{version} because the build process needs it.")
      system(jruby_bin, "-S", "gem", "install", name, "-v", version, "--no-ri", "--no-rdoc")
      raise RuntimeError, $!.to_s unless $?.success?
    end
    task.reenable # Allow this task to be run again
  end

  namespace "force" do
    task "gems" => ["vendor:gems"]
  end

  task "gems", [:bundle] do |task, args|
    require "bootstrap/environment"

    Rake::Task["dependency:rbx-stdlib"] if LogStash::Environment.ruby_engine == "rbx"
    Rake::Task["dependency:bundler"].invoke

    puts("Invoking bundler install...")
    output, exception = LogStash::Bundler.invoke!(:install => true)
    puts(output)
    raise(exception) if exception
  end # task gems
  task "all" => "gems"

  desc "Clean the vendored files"
  task :clean do
    rm_rf(vendor)
  end
end
