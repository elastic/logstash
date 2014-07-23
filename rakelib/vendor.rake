
DOWNLOADS = {
  "elasticsearch" => { "version" => "1.3.0", "sha1" => "f9e02e2cdcb55e7e8c5c60e955f793f68b7dec75" },
  "collectd" => { "version" => "5.4.0", "sha1" => "a90fe6cc53b76b7bdd56dc57950d90787cb9c96e" },
  #"jruby" => { "version" => "1.7.13", "sha1" => "0dfca68810a5eed7f12ae2007dc2cc47554b4cc6" }, # jruby-complete
  "jruby" => { "version" => "1.7.16", "sha1" => "4c912b648f6687622ba590ca2a28746d1cd5d550" },
  "kibana" => { "version" => "3.1.0", "sha1" => "effc20c83c0cb8d5e844d2634bd1854a1858bc43" },
  "geoip" => {
    "GeoLiteCity" => { "version" => "2013-01-18", "sha1" => "15aab9a90ff90c4784b2c48331014d242b86bf82", },
    "GeoIPASNum" => { "version" => "2014-02-12", "sha1" => "6f33ca0b31e5f233e36d1f66fbeae36909b58f91", }
  },
  "kafka" => { "version" => "0.8.1.1", "sha1" => "d73cc87fcb01c62fdad8171b7bb9468ac1156e75", "scala_version" => "2.9.2" },
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

  task "geoip" do |task, args|
    vendor_name = "geoip"
    parent = vendor(vendor_name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end.invoke unless Rake::Task.task_defined?(parent)

    vendor(vendor_name).tap { |v| mkdir_p v unless File.directory?(v) }
    files = DOWNLOADS[vendor_name]
    files.each do |name, info|
      version = info["version"]
      url = "http://logstash.objects.dreamhost.com/maxmind/#{name}-#{version}.dat.gz"
      download = file_fetch(url, info["sha1"])
      outpath = vendor(vendor_name, "#{name}.dat")
      tgz = Zlib::GzipReader.new(File.open(download))
      begin
        File.open(outpath, "w") do |out|
          IO::copy_stream(tgz, out)
        end
      rescue
        File.unlink(outpath) if File.file?(outpath)
        raise
      end
      tgz.close
    end
  end
  task "all" => "geoip"

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

  task "kafka" do |task, args|
    name = task.name.split(":")[1]
    info = DOWNLOADS[name]
    version = info["version"]
    scala_version = info["scala_version"]
    url = "https://archive.apache.org/dist/kafka/#{version}/kafka_#{scala_version}-#{version}.tgz"
    download = file_fetch(url, info["sha1"])

    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end.invoke unless Rake::Task.task_defined?(parent)

    untar(download) do |entry|
      next unless entry.full_name =~ /\.jar$/
      vendor(name, File.basename(entry.full_name))
    end
  end # task kafka
  task "all" => "kafka"

  task "elasticsearch" do |task, args|
    name = task.name.split(":")[1]
    info = DOWNLOADS[name]
    version = info["version"]
    url = "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{version}.tar.gz"
    download = file_fetch(url, info["sha1"])

    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end.invoke unless Rake::Task.task_defined?(parent)

    untar(download) do |entry|
      next unless entry.full_name =~ /\.jar$/
      vendor(name, File.basename(entry.full_name))
    end # untar
  end # task elasticsearch
  task "all" => "elasticsearch"

  task "collectd" do |task, args|
    name = task.name.split(":")[1]
    info = DOWNLOADS[name]
    version = info["version"]
    sha1 = info["sha1"]
    url = "https://collectd.org/files/collectd-#{version}.tar.gz"

    download = file_fetch(url, sha1)

    parent = vendor(name).gsub(/\/$/, "")
    directory parent => "vendor" do
      mkdir parent
    end unless Rake::Task.task_defined?(parent)

    file vendor(name, "types.db") => [download, parent] do |task, args|
      next if File.exists?(task.name)
      untar(download) do |entry|
        next unless entry.full_name == "collectd-#{version}/src/types.db"
        vendor(name, File.basename(entry.full_name))
      end # untar
    end.invoke
  end
  task "all" => "collectd"

  task "gems" => [ "dependency:bundler" ] do
    require "logstash/environment"
    Rake::Task["dependency:rbx-stdlib"] if LogStash::Environment.ruby_engine == "rbx"
    Rake::Task["dependency:stud"].invoke

    # Skip bundler if we've already done this recently.
    donefile = File.join(LogStash::Environment.gem_home, ".done")
    if File.file?(donefile) 
      age = (Time.now - File.lstat(donefile).mtime)
      # Skip if the donefile was last modified recently
      next if age < 300
    end

    # Try installing a few times in case we hit the "bad_record_mac" ssl error during installation.
    10.times do
      begin
        #Bundler::CLI.start(["install", "--gemfile=tools/Gemfile", "--path", LogStash::Environment.gem_home, "--clean", "--standalone", "--without", "development", "--jobs", 4])
        # There doesn't seem to be a way to invoke Bundler::CLI *and* have a
        # different GEM_HOME set that doesn't impact Bundler's view of what
        # gems are available. I asked about this in #bundler on freenode, and I
        # was told to stop using the bundler ruby api. Oh well :(
        bundler = File.join(Gem.bindir, "bundle")
        jruby = File.join("vendor", "jruby", "bin", "jruby")
        cmd = [jruby,  bundler, "install", "--gemfile=tools/Gemfile", "--path", LogStash::Environment::BUNDLE_DIR, "--standalone", "--clean", "--without", "development", "--jobs", "4"]
        system(*cmd)
        raise $! unless $?.success?
        break
      rescue Gem::RemoteFetcher::FetchError => e
        puts e.message
        puts e.backtrace.inspect
        sleep 5 #slow down a bit before retry
      end
    end
    File.write(donefile, Time.now.to_s)
  end # task gems
  task "all" => "gems"
end
