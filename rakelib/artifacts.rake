require "logstash/version"

namespace "artifact" do

  def package_files
    [
      "LICENSE",
      "CHANGELOG.md",
      "NOTICE.TXT",
      "CONTRIBUTORS",
      "bin/**/*",
      "lib/bootstrap/**/*",
      "lib/pluginmanager/**/*",
      "patterns/**/*",
      "vendor/??*/**/*",
      # To include ruby-maven's hidden ".mvn" directory, we need to
      # do add the line below. This directory contains a file called
      # "extensions.xml", which loads the ruby DSL for POMs.
      # Failing to include this file results in updates breaking for
      # plugins which use jar-dependencies.
      # See more in https://github.com/elastic/logstash/issues/4818
      "vendor/??*/**/.mvn/**/*",
      "Gemfile",
      "Gemfile.jruby-1.9.lock",
    ]
  end

  def exclude_paths
    return @exclude_paths if @exclude_paths

    @exclude_paths = []
    @exclude_paths << "**/*.gem"
    @exclude_paths << "**/test/files/slow-xpath.xml"
    @exclude_paths << "**/logstash-*/spec"
    @exclude_paths << "bin/bundle"

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

  # We create an empty bundle config file
  # This will allow the deb and rpm to create a file
  # with the correct user group and permission.
  task "clean-bundle-config" do
    FileUtils.mkdir_p(".bundle")
    File.open(".bundle/config", "w") { }
  end

  # locate the "gem "logstash-core" ..." line in Gemfile, and if the :path => "..." option if specified
  # build and install the local logstash-core gem otherwise just do nothing, bundler will deal with it.
  task "install-logstash-core" do
    # regex which matches a Gemfile gem definition for the logstash-core gem and captures the :path option
    gem_line_regex = /^\s*gem\s+["']logstash-core["'](?:\s*,\s*["'][^"^']+["'])?(?:\s*,\s*:path\s*=>\s*["']([^"^']+)["'])?/i

    lines = File.readlines("Gemfile")
    matches = lines.select{|line| line[gem_line_regex]}
    abort("ERROR: Gemfile format error, need a single logstash-core gem specification") if matches.size != 1

    path = matches.first[gem_line_regex, 1]

    if path
      Rake::Task["plugin:install-local-core-gem"].invoke("logstash-core", path)
    else
      puts("[artifact:install-logstash-core] using logstash-core from Rubygems")
    end
  end

  # # locate the "gem "logstash-core-event*" ..." line in Gemfile, and if the :path => "." option if specified
  # # build and install the local logstash-core-event* gem otherwise just do nothing, bundler will deal with it.
  task "install-logstash-core-event" do
    # regex which matches a Gemfile gem definition for the logstash-core-event* gem and captures the gem name and :path option
    gem_line_regex = /^\s*gem\s+["'](logstash-core-event[^"^']*)["'](?:\s*,\s*["'][^"^']+["'])?(?:\s*,\s*:path\s*=>\s*["']([^"^']+)["'])?/i

    lines = File.readlines("Gemfile")
    matches = lines.select{|line| line[gem_line_regex]}
    abort("ERROR: Gemfile format error, need a single logstash-core-event gem specification") if matches.size != 1

    name = matches.first[gem_line_regex, 1]
    path = matches.first[gem_line_regex, 2]

    if path
      Rake::Task["plugin:install-local-core-gem"].invoke(name, path)
    else
      puts("[artifact:install-logstash-core] using #{name} from Rubygems")
    end
  end

  # locate the "gem "logstash-core-plugin-api" ..." line in Gemfile, and if the :path => "..." option if specified
  # build and install the local logstash-core-plugin-api gem otherwise just do nothing, bundler will deal with it.
  task "install-logstash-core-plugin-api" do
    # regex which matches a Gemfile gem definition for the logstash-core gem and captures the :path option
    gem_line_regex = /^\s*gem\s+["']logstash-core-plugin-api["'](?:\s*,\s*["'][^"^']+["'])?(?:\s*,\s*:path\s*=>\s*["']([^"^']+)["'])?/i

    lines = File.readlines("Gemfile")
    matches = lines.select{|line| line[gem_line_regex]}
    abort("ERROR: Gemfile format error, need a single logstash-core-plugin-api gem specification") if matches.size != 1

    path = matches.first[gem_line_regex, 1]

    if path
      Rake::Task["plugin:install-local-core-gem"].invoke("logstash-core-plugin-api", path)
    else
      puts("[artifact:install-logstash-core-plugin-api] using logstash-core from Rubygems")
    end
  end

  task "prepare" => ["bootstrap", "plugin:install-default", "install-logstash-core", "install-logstash-core-event", "install-logstash-core-plugin-api", "clean-bundle-config"]
  task "prepare-all" => ["bootstrap", "plugin:install-all", "install-logstash-core", "install-logstash-core-event", "install-logstash-core-plugin-api", "clean-bundle-config"]

  desc "Build a tar.gz of default logstash plugins with all dependencies"
  task "tar" => ["prepare"] do
    puts("[artifact:tar] Building tar.gz of default plugins")
    build_tar
  end

  desc "Build a tar.gz of all logstash plugins from logstash-plugins github repo"
  task "tar-all-plugins" => ["prepare-all"] do
    puts("[artifact:tar] Building tar.gz of all plugins")
    build_tar "-all-plugins"
  end

  def build_tar(tar_suffix = nil)
    require "zlib"
    require "archive/tar/minitar"
    require "logstash/version"
    tarpath = "build/logstash#{tar_suffix}-#{LOGSTASH_VERSION}.tar.gz"
    puts("[artifact:tar] building #{tarpath}")
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

  desc "Build a zip of default logstash plugins with all dependencies"
  task "zip" => ["prepare"] do
    puts("[artifact:zip] Building zip of default plugins")
    build_zip
  end

  desc "Build a zip of all logstash plugins from logstash-plugins github repo"
  task "zip-all-plugins" => ["prepare-all"] do
    puts("[artifact:zip] Building zip of all plugins")
    build_zip "-all-plugins"
  end

  def build_zip(zip_suffix = "")
    require 'zip'
    zippath = "build/logstash#{zip_suffix}-#{LOGSTASH_VERSION}.zip"
    puts("[artifact:zip] building #{zippath}")
    File.unlink(zippath) if File.exists?(zippath)
    Zip::File.open(zippath, Zip::File::CREATE) do |zipfile|
      files.each do |path|
        path_in_zip = "logstash-#{LOGSTASH_VERSION}/#{path}"
        zipfile.add(path_in_zip, path)
      end
    end
    puts "Complete: #{zippath}"
  end

  def package(platform, version, package_name)
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
        # produce: logstash-5.0.0-alpha1.noarch.rpm
        package_filename = "logstash-#{LOGSTASH_VERSION}.ARCH.TYPE"

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
        out.attributes[:rpm_os] = "linux"
        out.config_files << "etc/sysconfig/logstash"
        out.config_files << "etc/logrotate.d/logstash"
        out.config_files << "/etc/init.d/logstash"
      when "debian", "ubuntu"
        # produce: logstash-5.0.0-alpha1_all.deb"
        package_filename = "logstash-#{LOGSTASH_VERSION}_ARCH.TYPE"

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

    out.name = package_name
    out.version = LOGSTASH_VERSION.gsub(/[.-]([[:alpha:]])/, '~\1')
    out.architecture = "all"
    # TODO(sissel): Include the git commit hash?
    out.iteration = "1" # what revision?
    out.url = "http://www.elasticsearch.org/overview/logstash/"
    out.description = "An extensible logging pipeline"
    out.vendor = "Elasticsearch"
    out.dependencies << "logrotate"

    # Because we made a mistake in naming the RC version numbers, both rpm and deb view
    # "1.5.0.rc1" higher than "1.5.0". Setting the epoch to 1 ensures that we get a kind
    # of clean slate as to how we compare package versions. The default epoch is 0, and
    # epoch is sorted first, so a version 1:1.5.0 will have greater priority
    # than 1.5.0.rc4
    out.epoch = 1

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
      path = File.join(basedir, "build", out.to_s(package_filename))
      x = out.output(path)
      puts "Completed: #{path}"
    ensure
      out.cleanup
    end
  end # def package

  desc "Build an RPM of logstash with all dependencies"
  task "rpm" => ["prepare"] do
    puts("[artifact:rpm] building rpm package")
    package("centos", "5", "logstash")
  end

  desc "Build a DEB of logstash with all dependencies"
  task "deb" => ["prepare"] do
    puts("[artifact:deb] building deb package")
    package("ubuntu", "12.04", "logstash")
  end
  
  desc "Build an RPM of logstash with all dependencies"
  task "rpm-all-plugins" => ["prepare-all"] do
    puts("[artifact:rpm-all-plugins] building rpm package")
    package("centos", "5", "logstash-all-plugins")
  end

  desc "Build a DEB of logstash with all dependencies"
  task "deb-all-plugins" => ["prepare-all"] do
    puts("[artifact:deb-all-plugins] building deb package")
    package("ubuntu", "12.04", "logstash-all-plugins")
  end
  
end
