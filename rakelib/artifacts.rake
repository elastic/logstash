namespace "artifact" do

  def package_files
    [
      ".bundle/config",
      "LICENSE",
      "CHANGELOG",
      "CONTRIBUTORS",
      "{bin,lib,spec,locales}/{,**/*}",
      "patterns/**/*",
      "vendor/??*/**/*",
      "Gemfile*",
      "logstash-core.gemspec",
    ]
  end

  def exclude_paths
    return @exclude_paths if @exclude_paths

    @exclude_paths = []
    @exclude_paths << "spec/reports/**/*"
    @exclude_paths << "**/*.gem"
    @exclude_paths << "**/test/files/slow-xpath.xml"
    @exclude_paths << "**/logstash-*/spec"
    @exclude_paths << "bin/bundle"
    @exclude_paths << "bin/rspec"

    @exclude_paths
  end

  def excludes
    return @excludes if @excludes
    @excludes = exclude_paths.collect { |g| Rake::FileList[g] }.flatten
  end

  def exclude?(path)
    excludes.any? { |ex| path == ex || (File.directory?(ex) && path =~ /^#{ex}\//) }
  end

  def files
    return @files if @files
    @files = package_files.collect do |glob|
      Rake::FileList[glob].reject { |path| exclude?(path) }
    end.flatten.uniq
  end

  task "use-defaults-gemfile" do
    FileUtils.cp("Gemfile.defaults", "Gemfile")
    FileUtils.cp("Gemfile.jruby-1.9.lock.defaults", "Gemfile.jruby-1.9.lock")
  end

  task "freeze-defaults-gemfile" => ["bootstrap", "plugin:install-default"] do
    FileUtils.cp("Gemfile", "Gemfile.defaults")
    FileUtils.cp("Gemfile.jruby-1.9.lock", "Gemfile.jruby-1.9.lock.defaults")
  end

  # We create an empty bundle config file
  # This will allow the deb and rpm to create a file
  # with the correct user group and permission.
  task "clean-bundle-config" do
    FileUtils.mkdir_p(".bundle")
    File.open(".bundle/config", "w") { }
  end

  task "prepare" => ["bootstrap", "use-defaults-gemfile", "plugin:install-default", "clean-bundle-config"]

  desc "Build a tar.gz of logstash with all dependencies"
  task "tar" => ["prepare"] do
    require "zlib"
    require "archive/tar/minitar"
    require "logstash/version"
    tarpath = "build/logstash-#{LOGSTASH_VERSION}.tar.gz"
    gz = Zlib::GzipWriter.new(File.new(tarpath, "wb"), Zlib::BEST_COMPRESSION)
    tar = Archive::Tar::Minitar::Output.new(gz)
    files.each do |path|
      stat = File.lstat(path)
      path_in_tar = "logstash-#{LOGSTASH_VERSION}/#{path}"
      opts = {
        :size => stat.size,
        :mode => stat.mode,
        :mtime => stat.mtime
      }
      if stat.directory?
        tar.tar.mkdir(path_in_tar, opts)
      else
        tar.tar.add_file_simple(path_in_tar, opts) do |io|
          File.open(path,'rb') do |fd|
            chunk = nil
            size = 0
            size += io.write(chunk) while chunk = fd.read(16384)
            if stat.size != size
              raise "Failure to write the entire file (#{path}) to the tarball. Expected to write #{stat.size} bytes; actually write #{size}"
            end
          end
        end
      end
    end
    tar.close
    gz.close
    puts "Complete: #{tarpath}"
  end

  task "zip" => ["prepare"] do
    Rake::Task["dependency:rubyzip"].invoke
    require 'zip'
    zippath = "build/logstash-#{LOGSTASH_VERSION}.zip"
    File.unlink(zippath) if File.exists?(zippath)
    Zip::File.open(zippath, Zip::File::CREATE) do |zipfile|
      files.each do |path|
        path_in_zip = "logstash-#{LOGSTASH_VERSION}/#{path}"
        zipfile.add(path_in_zip, path)
      end
    end
    puts "Complete: #{zippath}"
  end

  def package(platform, version)
    Rake::Task["dependency:fpm"].invoke
    Rake::Task["dependency:stud"].invoke
    require "stud/temporary"
    require "fpm/errors" # TODO(sissel): fix this in fpm
    require "fpm/package/dir"
    require "fpm/package/gem" # TODO(sissel): fix this in fpm; rpm needs it.

    dir = FPM::Package::Dir.new

    files.each do |path|
      next if File.directory?(path)
      dir.input("#{path}=/opt/logstash/#{path}")
    end

    basedir = File.join(File.dirname(__FILE__), "..")

    File.join(basedir, "pkg", "logrotate.conf").tap do |path|
      dir.input("#{path}=/etc/logrotate.d/logstash")
    end

    # Create an empty /var/log/logstash/ directory in the package
    # This is a bit obtuse, I suppose, but it is necessary until
    # we find a better way to do this with fpm.
    Stud::Temporary.directory do |empty|
      dir.input("#{empty}/=/var/log/logstash")
      dir.input("#{empty}/=/var/lib/logstash")
      dir.input("#{empty}/=/etc/logstash/conf.d")
    end

    case platform
      when "redhat", "centos"
        File.join(basedir, "pkg", "logrotate.conf").tap do |path|
          dir.input("#{path}=/etc/logrotate.d/logstash")
        end
        File.join(basedir, "pkg", "logstash.default").tap do |path|
          dir.input("#{path}=/etc/sysconfig/logstash")
        end
        File.join(basedir, "pkg", "logstash.sysv").tap do |path|
          dir.input("#{path}=/etc/init.d/logstash")
        end
        require "fpm/package/rpm"
        out = dir.convert(FPM::Package::RPM)
        out.license = "ASL 2.0" # Red Hat calls 'Apache Software License' == ASL
        out.attributes[:rpm_use_file_permissions] = true
        out.attributes[:rpm_user] = "root"
        out.attributes[:rpm_group] = "root"
        out.config_files << "etc/sysconfig/logstash"
        out.config_files << "etc/logrotate.d/logstash"
        out.config_files << "/etc/init.d/logstash"
      when "debian", "ubuntu"
        File.join(basedir, "pkg", "logstash.default").tap do |path|
          dir.input("#{path}=/etc/default/logstash")
        end
        File.join(basedir, "pkg", "logstash.sysv").tap do |path|
          dir.input("#{path}=/etc/init.d/logstash")
        end
        require "fpm/package/deb"
        out = dir.convert(FPM::Package::Deb)
        out.license = "Apache 2.0"
        out.attributes[:deb_user] = "root"
        out.attributes[:deb_group] = "root"
        out.attributes[:deb_suggests] = "java7-runtime-headless"
        out.config_files << "/etc/default/logstash"
        out.config_files << "/etc/logrotate.d/logstash"
        out.config_files << "/etc/init.d/logstash"
    end

    # Packaging install/removal scripts
    ["before", "after"].each do |stage|
      ["install", "remove"].each do |action|
        script = "#{stage}-#{action}" # like, "before-install"
        script_sym = script.gsub("-", "_").to_sym
        script_path = File.join(File.dirname(__FILE__), "..", "pkg", platform, "#{script}.sh")
        next unless File.exists?(script_path)

        out.scripts[script_sym] = File.read(script_path)
      end
    end

    # TODO(sissel): Invoke Pleaserun to generate the init scripts/whatever

    out.name = "logstash"
    out.version = LOGSTASH_VERSION
    out.architecture = "all"
    # TODO(sissel): Include the git commit hash?
    out.iteration = "1" # what revision?
    out.url = "http://www.elasticsearch.org/overview/logstash/"
    out.description = "An extensible logging pipeline"
    out.vendor = "Elasticsearch"
    out.dependencies << "logrotate"

    # We don't specify a dependency on Java because:
    # - On Red Hat, Oracle and Red Hat both label their java packages in
    #   incompatible ways. Further, there is no way to guarantee a qualified
    #   version is available to install.
    # - On Debian and Ubuntu, there is no Oracle package and specifying a
    #   correct version of OpenJDK is impossible because there is no guarantee that
    #   is impossible for the same reasons as the Red Hat section above.
    # References:
    # - http://www.elasticsearch.org/blog/java-1-7u55-safe-use-elasticsearch-lucene/
    # - deb: https://github.com/elasticsearch/logstash/pull/1008
    # - rpm: https://github.com/elasticsearch/logstash/pull/1290
    # - rpm: https://github.com/elasticsearch/logstash/issues/1673
    # - rpm: https://logstash.jira.com/browse/LOGSTASH-1020

    out.attributes[:force?] = true # overwrite the rpm/deb/etc being created
    begin
      path = File.join(basedir, "build", out.to_s)
      x = out.output(path)
      puts "Completed: #{path}"
    ensure
      out.cleanup
    end
  end # def package

  desc "Build an RPM of logstash with all dependencies"
  task "rpm" => ["prepare"] do
    package("centos", "5")
  end

  desc "Build an RPM of logstash with all dependencies"
  task "deb" => ["prepare"] do
    package("ubuntu", "12.04")
  end
end

