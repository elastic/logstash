DOWNLOADS = {
  "jruby" => { "version" => "1.7.16", "sha1" => "4c912b648f6687622ba590ca2a28746d1cd5d550" },
  "kibana" => { "version" => "3.1.2", "sha1" => "a59ea4abb018a7ed22b3bc1c3bcc6944b7009dc4" },
}

def vendor(*args)
  return File.join("vendor", *args)
end

# Untar any files from the given tarball file name.
#
# A tar entry is passed to the block. The block should should return
# * nil to skip this file
# * or, the desired string filename to write the file to.
def untar(tarball, &block)
  Rake::Task["dependency:archive-tar-minitar"].invoke
  require "archive/tar/minitar"
  tgz = Zlib::GzipReader.new(File.open(tarball))
  # Pull out typesdb
  tar = Archive::Tar::Minitar::Input.open(tgz)
  tar.each do |entry|
    path = block.call(entry)
    next if path.nil?
    parent = File.dirname(path)

    mkdir_p parent unless File.directory?(parent)

    # Skip this file if the output file is the same size
    if entry.directory?
      mkdir path unless File.directory?(path)
    else
      entry_mode = entry.instance_eval { @mode } & 0777
      if File.exists?(path)
        stat = File.stat(path)
        # TODO(sissel): Submit a patch to archive-tar-minitar upstream to
        # expose headers in the entry.
        entry_size = entry.instance_eval { @size }
        # If file sizes are same, skip writing.
        next if stat.size == entry_size && (stat.mode & 0777) == entry_mode
      end
      puts "Extracting #{entry.full_name} from #{tarball} #{entry_mode.to_s(8)}"
      File.open(path, "w") do |fd|
        # eof? check lets us skip empty files. Necessary because the API provided by
        # Archive::Tar::Minitar::Reader::EntryStream only mostly acts like an
        # IO object. Something about empty files in this EntryStream causes
        # IO.copy_stream to throw "can't convert nil into String" on JRuby
        # TODO(sissel): File a bug about this.
        while !entry.eof?
          chunk = entry.read(16384)
          fd.write(chunk)
        end
          #IO.copy_stream(entry, fd)
      end
      File.chmod(entry_mode, path)
    end
  end
  tar.close
end # def untar

namespace "vendor" do
  task "jruby" do |task, args|
    name = task.name.split(":")[1]
    info = DOWNLOADS[name]
    version = info["version"]
    #url = "http://jruby.org.s3.amazonaws.com/downloads/#{version}/jruby-complete-#{version}.jar"
    url = "http://jruby.org.s3.amazonaws.com/downloads/#{version}/jruby-bin-#{version}.tar.gz"

    download = file_fetch(url, info["sha1"])
    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end.invoke unless Rake::Task.task_defined?(parent)

    prefix_re = /^#{Regexp.quote("jruby-#{version}/")}/
    untar(download) do |entry|
      out = entry.full_name.gsub(prefix_re, "")
      next if out =~ /^samples/
      next if out =~ /@LongLink/
      vendor(name, out)
    end # untar
  end # jruby
  task "all" => "jruby"
  task "test" => "jruby"

  task "kibana" do |task, args|
    name = task.name.split(":")[1]
    info = DOWNLOADS[name]
    version = info["version"]
    url = "https://download.elasticsearch.org/kibana/kibana/kibana-#{version}.tar.gz"
    download = file_fetch(url, info["sha1"])

    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end.invoke unless Rake::Task.task_defined?(parent)

    prefix_re = /^#{Regexp.quote("kibana-#{version}/")}/
    untar(download) do |entry|
      vendor(name, entry.full_name.gsub(prefix_re, ""))
    end # untar
  end # task kibana
  task "all" => "kibana"
  task "test" => "kibana"

  namespace "force" do
    task "gems" => ["vendor:gems"]
  end

  task "gems", [:bundle] do |task, args|
    require "logstash/environment"
    Rake::Task["dependency:rbx-stdlib"] if LogStash::Environment.ruby_engine == "rbx"
    Rake::Task["dependency:stud"].invoke
    Rake::Task["vendor:bundle"].invoke("tools/Gemfile") if args.to_hash.empty? || args[:bundle]

  end # task gems
  task "all" => "gems"

  task "bundle", [:gemfile] => [ "dependency:bundler" ] do |task, args|
    task.reenable
    # because --path creates a .bundle/config file and changes bundler path
    # we need to remove this file so it doesn't influence following bundler calls
    FileUtils.rm_rf(::File.join(LogStash::Environment::LOGSTASH_HOME, "tools/.bundle"))
    10.times do
      begin
        ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
        ENV["BUNDLE_PATH"] = LogStash::Environment.logstash_gem_home
        ENV["BUNDLE_GEMFILE"] = args[:gemfile]
        Bundler.reset!
        Bundler::CLI.start(LogStash::Environment.bundler_install_command(args[:gemfile], LogStash::Environment::BUNDLE_DIR))
        break
      rescue => e
        # for now catch all, looks like bundler now throws Bundler::InstallError, Errno::EBADF
        puts(e.message)
        puts("--> Retrying vendor:gems upon exception=#{e.class}")
        sleep(1)
      end
    end

    # because --path creates a .bundle/config file and changes bundler path
    # we need to remove this file so it doesn't influence following bundler calls
    FileUtils.rm_rf(::File.join(LogStash::Environment::LOGSTASH_HOME, "tools/.bundle"))
  end

  desc "Clean the vendored files"
  task :clean do
    rm_rf vendor
  end
end
