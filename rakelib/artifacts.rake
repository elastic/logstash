namespace "artifact" do

  SNAPSHOT_BUILD = ENV["RELEASE"] != "1"
  PACKAGE_SUFFIX = SNAPSHOT_BUILD ? "-SNAPSHOT" : ""

  def package_files
    [
      "NOTICE.TXT",
      "CONTRIBUTORS",
      "bin/**/*",
      "config/**/*",
      "data",
      "modules/**/*",

      "lib/bootstrap/**/*",
      "lib/pluginmanager/**/*",
      "lib/systeminstall/**/*",
      "lib/secretstore/**/*",

      "logstash-core/lib/**/*",
      "logstash-core/locales/**/*",
      "logstash-core/vendor/**/*",
      "logstash-core/versions-gem-copy.yml",
      "logstash-core/*.gemspec",

      "logstash-core-plugin-api/lib/**/*",
      "logstash-core-plugin-api/*.gemspec",

      "patterns/**/*",
      "tools/ingest-converter/build/libs/ingest-converter.jar",
      "vendor/??*/**/*",
      # To include ruby-maven's hidden ".mvn" directory, we need to
      # do add the line below. This directory contains a file called
      # "extensions.xml", which loads the ruby DSL for POMs.
      # Failing to include this file results in updates breaking for
      # plugins which use jar-dependencies.
      # See more in https://github.com/elastic/logstash/issues/4818
      "vendor/??*/**/.mvn/**/*",
      "Gemfile",
      "Gemfile.lock",
      "x-pack/**/*",
    ]
  end

  def exclude_paths
    return @exclude_paths if @exclude_paths

    @exclude_paths = []
    @exclude_paths << "**/*.gem"
    @exclude_paths << "**/test/files/slow-xpath.xml"
    @exclude_paths << "**/logstash-*/spec"
    @exclude_paths << "bin/bundle"
    @exclude_paths << "bin/rspec"
    @exclude_paths << "bin/rspec.bat"

    @exclude_paths
  end

  def excludes
    return @excludes if @excludes
    @excludes = exclude_paths.collect { |g| Rake::FileList[g] }.flatten
  end

  def exclude?(path)
    excludes.any? { |ex| path_matches_exclude?(path, ex) }
  end

  def exclude_oss?(path)
    path_matches_exclude?(path, "x-pack" ) || exclude?(path)
  end

  def oss_excluder
    @oss_excluder ||= self.method(:exclude_oss?)
  end

  def path_matches_exclude?(path, ex)
    path == ex || (File.directory?(ex) && path =~ /^#{ex}\//)
  end

  def files(excluder=nil)
    excluder ||= self.method(:exclude?)

    package_files.collect do |glob|
      Rake::FileList[glob].reject(&excluder)
    end.flatten.uniq
  end

  desc "Generate rpm, deb, tar and zip artifacts"
  task "all" => ["prepare", "build"]

  desc "Build a tar.gz of default logstash plugins with all dependencies"
  task "tar" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:tar] Building tar.gz of default plugins")
    build_tar('ELASTIC-LICENSE')
  end

  desc "Build an OSS tar.gz of default logstash plugins with all dependencies"
  task "tar_oss" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:tar] Building tar.gz of default plugins")
    build_tar('APACHE-LICENSE-2.0', "-oss", oss_excluder)
  end

  desc "Build a zip of default logstash plugins with all dependencies"
  task "zip" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:zip] Building zip of default plugins")
    build_zip('ELASTIC-LICENSE')
  end

  desc "Build a zip of default logstash plugins with all dependencies"
  task "zip_oss" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:zip] Building zip of default plugins")
    build_zip('APACHE-LICENSE-2.0',"-oss", oss_excluder)
  end


  desc "Build an RPM of logstash with all dependencies"
  task "rpm" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:rpm] building rpm package")
    package("centos", "5")
  end

  desc "Build an RPM of logstash with all dependencies"
  task "rpm_oss" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:rpm] building rpm package")
    package("centos", "5", :oss)
  end


  desc "Build a DEB of logstash with all dependencies"
  task "deb" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:deb] building deb package")
    package("ubuntu", "12.04")
  end

  desc "Build a DEB of logstash with all dependencies"
  task "deb_oss" => ["prepare", "generate_build_metadata", "license:generate-notice-file"] do
    puts("[artifact:deb] building deb package")
    package("ubuntu", "12.04", :oss)
  end

  desc "Generate logstash core gems"
  task "gems" => ["prepare"] do
    Rake::Task["artifact:build-logstash-core"].invoke
    Rake::Task["artifact:build-logstash-core-plugin-api"].invoke
  end

  # "all-plugins" version of tasks
  desc "Generate rpm, deb, tar and zip artifacts (\"all-plugins\" version)"
  task "all-all-plugins" => ["prepare-all", "build"]

  desc "Build a zip of all logstash plugins from logstash-plugins github repo"
  task "zip-all-plugins" => ["prepare-all", "generate_build_metadata"] do
    puts("[artifact:zip] Building zip of all plugins")
    build_zip('ELASTIC-LICENSE', "-all-plugins")
  end

  desc "Build a tar.gz of all logstash plugins from logstash-plugins github repo"
  task "tar-all-plugins" => ["prepare-all", "generate_build_metadata"] do
    puts("[artifact:tar] Building tar.gz of all plugins")
    build_tar('ELASTIC-LICENSE', "-all-plugins")
  end

  # Auxiliary tasks
  task "build" => [:generate_build_metadata] do
    Rake::Task["artifact:gems"].invoke unless SNAPSHOT_BUILD
    Rake::Task["artifact:deb"].invoke
    Rake::Task["artifact:deb_oss"].invoke
    Rake::Task["artifact:rpm"].invoke
    Rake::Task["artifact:rpm_oss"].invoke
    Rake::Task["artifact:zip"].invoke
    Rake::Task["artifact:zip_oss"].invoke
    Rake::Task["artifact:tar"].invoke
    Rake::Task["artifact:tar_oss"].invoke
  end

  task "generate_build_metadata" do
    return if defined?(BUILD_METADATA_FILE)
    BUILD_METADATA_FILE = Tempfile.new('build.rb')
    build_info = {
      "build_date" => Time.now.iso8601,
      "build_sha" => `git rev-parse HEAD`.chomp,
      "build_snapshot" => SNAPSHOT_BUILD
    }
    metadata = [ "# encoding: utf-8", "BUILD_INFO = #{build_info}" ]
    IO.write(BUILD_METADATA_FILE.path, metadata.join("\n"))
  end

  # We create an empty bundle config file
  # This will allow the deb and rpm to create a file
  # with the correct user group and permission.
  task "clean-bundle-config" do
    FileUtils.mkdir_p(".bundle")
    File.open(".bundle/config", "w") { }
  end

  # locate the "gem "logstash-core" ..." line in Gemfile, and if the :path => "..." option if specified
  # build the local logstash-core gem otherwise just do nothing, bundler will deal with it.
  task "build-logstash-core" do
    # regex which matches a Gemfile gem definition for the logstash-core gem and captures the :path option
    gem_line_regex = /^\s*gem\s+["']logstash-core["'](?:\s*,\s*["'][^"^']+["'])?(?:\s*,\s*:path\s*=>\s*["']([^"^']+)["'])?/i

    lines = File.readlines("Gemfile")
    matches = lines.select{|line| line[gem_line_regex]}
    abort("ERROR: Gemfile format error, need a single logstash-core gem specification") if matches.size != 1

    path = matches.first[gem_line_regex, 1]

    if path
      Rake::Task["plugin:build-local-core-gem"].invoke("logstash-core", path)
    else
      puts "The Gemfile should reference \"logstash-core\" gem locally through :path, but found instead: #{matches}"
      exit(1)
    end
  end

  # locate the "gem "logstash-core-plugin-api" ..." line in Gemfile, and if the :path => "..." option if specified
  # build the local logstash-core-plugin-api gem otherwise just do nothing, bundler will deal with it.
  task "build-logstash-core-plugin-api" do
    # regex which matches a Gemfile gem definition for the logstash-core gem and captures the :path option
    gem_line_regex = /^\s*gem\s+["']logstash-core-plugin-api["'](?:\s*,\s*["'][^"^']+["'])?(?:\s*,\s*:path\s*=>\s*["']([^"^']+)["'])?/i

    lines = File.readlines("Gemfile")
    matches = lines.select{|line| line[gem_line_regex]}
    abort("ERROR: Gemfile format error, need a single logstash-core-plugin-api gem specification") if matches.size != 1

    path = matches.first[gem_line_regex, 1]

    if path
      Rake::Task["plugin:build-local-core-gem"].invoke("logstash-core-plugin-api", path)
    else
      puts "The Gemfile should reference \"logstash-core-plugin-api\" gem locally through :path, but found instead: #{matches}"
      exit(1)
    end
  end

  task "prepare" do
    if ENV['SKIP_PREPARE'] != "1"
      ["bootstrap", "plugin:install-default", "artifact:clean-bundle-config"].each {|task| Rake::Task[task].invoke }
    end
  end

  def ensure_logstash_version_constant_defined
    # we do not want this file required when rake (ruby) parses this file
    # only when there is a task executing, not at the very top of this file
    if !defined?(LOGSTASH_VERSION)
      require "logstash/version"
    end
  end

  def build_tar(license, tar_suffix = nil, excluder=nil)
    require "zlib"
    require "archive/tar/minitar"
    ensure_logstash_version_constant_defined
    tarpath = "build/logstash#{tar_suffix}-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}.tar.gz"
    puts("[artifact:tar] building #{tarpath}")
    gz = Zlib::GzipWriter.new(File.new(tarpath, "wb"), Zlib::BEST_COMPRESSION)
    tar = Archive::Tar::Minitar::Output.new(gz)
    files(excluder).each do |path|
      write_to_tar(tar, path, "logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}/#{path}")
    end

    source_license_path = "licenses/#{license}.txt"
    fail("Missing source license: #{source_license_path}") unless File.exists?(source_license_path)
    write_to_tar(tar, source_license_path, "logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}/LICENSE.txt")

    # add build.rb to tar
    metadata_file_path_in_tar = File.join("logstash-core", "lib", "logstash", "build.rb")
    path_in_tar = File.join("logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}", metadata_file_path_in_tar)
    write_to_tar(tar, BUILD_METADATA_FILE.path, path_in_tar)

    tar.close
    gz.close
    puts "Complete: #{tarpath}"
  end

  def write_to_tar(tar, path, path_in_tar)
    stat = File.lstat(path)
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

  def build_zip(license, zip_suffix = "", excluder=nil)
    require 'zip'
    ensure_logstash_version_constant_defined
    zippath = "build/logstash#{zip_suffix}-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}.zip"
    puts("[artifact:zip] building #{zippath}")
    File.unlink(zippath) if File.exists?(zippath)
    Zip::File.open(zippath, Zip::File::CREATE) do |zipfile|
      files(excluder).each do |path|
        path_in_zip = "logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}/#{path}"
        zipfile.add(path_in_zip, path)
      end

      source_license_path = "licenses/#{license}.txt"
      fail("Missing source license: #{source_license_path}") unless File.exists?(source_license_path)
      zipfile.add("logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}/LICENSE.txt", source_license_path)

      # add build.rb to zip
      metadata_file_path_in_zip = File.join("logstash-core", "lib", "logstash", "build.rb")
      path_in_zip = File.join("logstash-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}", metadata_file_path_in_zip)
      path = BUILD_METADATA_FILE.path
      Zip.continue_on_exists_proc = true
      zipfile.add(path_in_zip, path)
    end
    puts "Complete: #{zippath}"
  end

  def package(platform, version, variant=:standard)
    oss = variant == :oss

    require "stud/temporary"
    require "fpm/errors" # TODO(sissel): fix this in fpm
    require "fpm/package/dir"
    require "fpm/package/gem" # TODO(sissel): fix this in fpm; rpm needs it.
    require "childprocess/jruby/pump"
    # TODO(ph): Cabin is closing the fd when it reach EOF, childprocess will attempt to write to it and hit an IOError.
    # This will make a the thread dies, in 1.7.25 we had a Thread Death
    require_relative "childprocess_patch"

    basedir = File.join(File.dirname(__FILE__), "..")
    dir = FPM::Package::Dir.new
    dir.attributes[:workdir] = File.join(basedir, "build", "fpm")

    metadata_file_path = File.join("logstash-core", "lib", "logstash", "build.rb")
    metadata_source_file_path = BUILD_METADATA_FILE.path
    dir.input("#{metadata_source_file_path}=/usr/share/logstash/#{metadata_file_path}")


    suffix = ""
    excluder = nil
    if oss
      suffix= "-oss"
      excluder = oss_excluder
    end

    files(excluder).each do |path|
      next if File.directory?(path)
      # Omit any config dir from /usr/share/logstash for packages, since we're
      # using /etc/logstash below
      next if path.start_with?("config/")
      dir.input("#{path}=/usr/share/logstash/#{path}")
    end

    if oss
      # Artifacts whose sources are exclusively licensed under the Apache License and
      # Apache-compatible licenses are distributed under the Apache License 2.0
      dir.input("licenses/APACHE-LICENSE-2.0.txt=/usr/share/logstash/LICENSE.txt")
    else
      # Artifacts whose sources include Elastic Commercial Software are distributed
      # under the Elastic License.
      dir.input("licenses/ELASTIC-LICENSE.txt=/usr/share/logstash/LICENSE.txt")
    end

    # Create an empty /var/log/logstash/ directory in the package
    # This is a bit obtuse, I suppose, but it is necessary until
    # we find a better way to do this with fpm.
    Stud::Temporary.directory do |empty|
      dir.input("#{empty}/=/usr/share/logstash/data")
      dir.input("#{empty}/=/var/log/logstash")
      dir.input("#{empty}/=/var/lib/logstash")
      dir.input("#{empty}/=/etc/logstash/conf.d")
    end

    File.join(basedir, "config", "log4j2.properties").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end

    ensure_logstash_version_constant_defined
    package_filename = "logstash#{suffix}-#{LOGSTASH_VERSION}#{PACKAGE_SUFFIX}.TYPE"

    File.join(basedir, "config", "startup.options").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end
    File.join(basedir, "config", "jvm.options").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end
    File.join(basedir, "config", "logstash.yml").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end
    File.join(basedir, "config", "logstash-sample.conf").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end
    File.join(basedir, "pkg", "pipelines.yml").tap do |path|
      dir.input("#{path}=/etc/logstash")
    end

    case platform
      when "redhat", "centos"
        require "fpm/package/rpm"

        # Red Hat calls 'Apache Software License' == ASL
        license = oss ? "ASL 2.0" : "Elastic License"

        out = dir.convert(FPM::Package::RPM)
        out.license = license
        out.attributes[:rpm_use_file_permissions] = true
        out.attributes[:rpm_user] = "root"
        out.attributes[:rpm_group] = "root"
        out.attributes[:rpm_os] = "linux"
        out.config_files << "/etc/logstash/startup.options"
        out.config_files << "/etc/logstash/jvm.options"
        out.config_files << "/etc/logstash/log4j2.properties"
        out.config_files << "/etc/logstash/logstash.yml"
        out.config_files << "/etc/logstash/logstash-sample.conf"
        out.config_files << "/etc/logstash/pipelines.yml"
      when "debian", "ubuntu"
        require "fpm/package/deb"

        license = oss ? "ASL-2.0" : "Elastic-License"

        out = dir.convert(FPM::Package::Deb)
        out.license = license
        out.attributes[:deb_user] = "root"
        out.attributes[:deb_group] = "root"
        out.attributes[:deb_suggests] = "java8-runtime-headless"
        out.config_files << "/etc/logstash/startup.options"
        out.config_files << "/etc/logstash/jvm.options"
        out.config_files << "/etc/logstash/log4j2.properties"
        out.config_files << "/etc/logstash/logstash.yml"
        out.config_files << "/etc/logstash/logstash-sample.conf"
        out.config_files << "/etc/logstash/pipelines.yml"
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
    out.version = LOGSTASH_VERSION.gsub(/[.-]([[:alpha:]])/, '~\1')
    out.architecture = "all"
    # TODO(sissel): Include the git commit hash?
    out.iteration = "1" # what revision?
    out.url = "http://www.elasticsearch.org/overview/logstash/"
    out.description = "An extensible logging pipeline"
    out.vendor = "Elasticsearch"

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
    # - https://github.com/elastic/logstash/issues/6275
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
end
