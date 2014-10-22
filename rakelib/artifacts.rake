def staging
  "build/staging"
end

namespace "artifact" do
  require "logstash/environment"
  def package_files
    [
      "LICENSE",
      "CHANGELOG",
      "CONTRIBUTORS",
      "{bin,lib,spec,locales}/{,**/*}",
      "patterns/**/*",
      "vendor/??*/**/*",
      File.join(LogStash::Environment.gem_home.gsub(Dir.pwd + "/", ""), "{gems,specifications}/**/*"),
      "Rakefile",
      "rakelib/*",
    ]
  end

  def exclude_globs
    return @exclude_globs if @exclude_globs
    @exclude_globs = []
    #gitignore = File.join(File.dirname(__FILE__), "..", ".gitignore")
    #if File.exists?(gitignore)
      #@exclude_globs += File.read(gitignore).split("\n")
    #end
    @exclude_globs << "spec/reports/**/*"
    @exclude_globs << "**/*.gem"
    @exclude_globs << "**/test/files/slow-xpath.xml"
    return @exclude_globs
  end

  def excludes
    return @excludes if @excludes
    @excludes = exclude_globs.collect { |g| Rake::FileList[g] }.flatten
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
  
  desc "Build a tar.gz of logstash with all dependencies"
  task "tar" => ["vendor:elasticsearch", "vendor:collectd", "vendor:jruby", "vendor:gems"] do
    require "zlib"
    require "archive/tar/minitar"
    require "logstash/version"
    tarpath = "build/logstash-#{LOGSTASH_VERSION}.tar.gz"
    tarfile = File.new(tarpath, "wb")
    gz = Zlib::GzipWriter.new(tarfile, Zlib::BEST_COMPRESSION)
    tar = Archive::Tar::Minitar::Output.new(gz)
    files.each do |path|
      Archive::Tar::Minitar.pack_file(path, tar)
    end
    tar.close
    gz.close
    puts "Complete: #{tarpath}"
  end

  def package(platform, version)
    Rake::Task["dependency:fpm"].invoke
    require "fpm/errors" # TODO(sissel): fix this in fpm
    require "fpm/package/dir"
    require "fpm/package/gem" # TODO(sissel): fix this in fpm; rpm needs it.

    dir = FPM::Package::Dir.new

    files.each do |path|
      next if File.directory?(path)
      p path
      dir.input("#{path}=/opt/logstash/#{path}")
    end

    basedir = File.join(File.dirname(__FILE__), "..")

    File.join(basedir, "pkg", "logrotate.conf").tap do |path|
      dir.input("#{path}=/etc/logrotate.d/logstash")
    end

    case platform
      when "redhat", "centos"
        File.join(basedir, "pkg", "logrotate.conf").tap do |path|
          dir.input("#{path}=/etc/logrotate.d/logstash")
        end
        File.join(basedir, "pkg", "logstash.default").tap do |path|
          dir.input("#{path}=/etc/sysconfig/logstash")
        end
        require "fpm/package/rpm"
        out = dir.convert(FPM::Package::RPM)
        out.license = "ASL 2.0" # Red Hat calls 'Apache Software License' == ASL
        out.attributes[:rpm_use_file_permissions] = true
        out.attributes[:rpm_user] = "root"
        out.attributes[:rpm_group] = "root"
        out.config_files << "etc/sysconfig/logstash"
        out.config_files << "etc/logrotate.d/logstash"
      when "debian", "ubuntu"
        File.join(basedir, "pkg", "logstash.default").tap do |path|
          dir.input("#{path}=/etc/default/logstash")
        end
        require "fpm/package/deb"
        out = dir.convert(FPM::Package::Deb)
        out.license = "Apache 2.0"
        out.attributes[:deb_user] = "root"
        out.attributes[:deb_group] = "root"
        out.attributes[:deb_suggests] = "java7-runtime-headless"
        # TODO(sissel): this file should go away once pleaserun is implemented.
        out.config_files << "/etc/default/logstash"

        out.config_files << "/etc/logrotate.d/logstash"
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
  task "rpm" => ["vendor:elasticsearch", "vendor:collectd", "vendor:jruby", "vendor:gems"] do
    package("centos", "5")
  end

  desc "Build an RPM of logstash with all dependencies"
  task "deb" do
    package("ubuntu", "12.04")
  end
end

