require 'tempfile'
require 'ftools'

LOGSTASH_VERSION = "0.9.1"

# Compile config grammar (ragel -> ruby)
file "lib/logstash/config/grammar.rb" => ["lib/logstash/config/grammar.rl"] do
  sh "make -C lib/logstash/config grammar.rb"
end

task :compile => "lib/logstash/config/grammar.rb" do |t|
  # Taken from 'jrubyc' 
  #  Currently this code is commented out because jruby emits this:
  #     Failure during compilation of file logstash/web/helpers/require_param.rb:
  #       java.lang.RuntimeException: java.io.FileNotFoundException: File path
  #       /home/jls/projects/logstash/logstash/web/helpers/require_param.rb
  #       does not start with parent path /home/jls/projects/logstash/lib
  #
  #     org/jruby/util/JavaNameMangler.java:105:in `mangleFilenameForClasspath'
  #     org/jruby/util/JavaNameMangler.java:32:in `mangleFilenameForClasspath'
  require 'jruby/jrubyc'
  #args = [ "-p", "net.logstash" ]
  args = ["-d", "build"]
  args += Dir.glob("**/*.rb")
  status = JRuby::Compiler::compile_argv(args)
  if (status != 0)
    puts "Compilation FAILED: #{status} error(s) encountered"
    exit status
  end

  #mkdir_p "build"
  #sh "rm -rf lib/net"
  #Dir.chdir("lib") do
    #args = Dir.glob("**/*.rb")
    ##sh "jrubyc", "-d", "../build" *args
    #sh "jrubyc", *args
  #end
end

VERSIONS = {
  :jruby => "1.6.0", # Any of CPL1.0/GPL2.0/LGPL2.1 ? Confusing, but OK.
  :elasticsearch => "0.15.2", # Apache 2.0 license
  :joda => "1.6.2",  # Apache 2.0 license
}

namespace :vendor do
  file "vendor/jar" do |t|
    mkdir_p mkdir(t.name)
  end

  # Download jruby.jar
  file "vendor/jar/jruby-complete-#{VERSIONS[:jruby]}.jar" => "vendor/jar" do |t|
    baseurl = "http://repository.codehaus.org/org/jruby/jruby-complete"
    if !File.exists?(t.name)
      sh "wget -O #{t.name} #{baseurl}/#{VERSIONS[:jruby]}/#{File.basename(t.name)}"
    end
  end # jruby

  task :jruby => "vendor/jar/jruby-complete-#{VERSIONS[:jruby]}.jar" do
    # nothing to do, the dep does it.
  end

  # Download elasticsearch + deps (for outputs/elasticsearch)
  task :elasticsearch => "vendor/jar" do
    version = VERSIONS[:elasticsearch]
    tarball = "elasticsearch-#{version}.tar.gz"
    url = "http://github.com/downloads/elasticsearch/elasticsearch/#{tarball}"
    if !File.exists?(tarball)
      # --no-check-certificate is for github and wget not supporting wildcard
      # certs sanely.
      sh "wget -O #{tarball} --no-check-certificate #{url}"
    end

    sh "tar -zxf #{tarball} -C vendor/jar/ elasticsearch-#{version}/lib"
  end # elasticsearch

  task :joda => "vendor/jar" do
    version = VERSIONS[:joda] 
    baseurl = "http://sourceforge.net/projects/joda-time/files/joda-time"
    tarball = "joda-time-#{version}-bin.tar.gz"
    url = "#{baseurl}/#{version}/#{tarball}/download"

    if !File.exists?(tarball)
      sh "wget -O #{tarball} #{url}"
    end

    sh "tar -zxf #{tarball} -C vendor/jar/ joda-time-#{version}/joda-time-#{version}.jar"
  end # joda

  task :gems => "vendor/jar" do
    puts "=> Installing gems to vendor/bundle/..."
    sh "bundle install --deployment"
  end
end # vendor namespace

namespace :package do
  task :gem do
    sh "gem build logstash.gemspec"
  end

  monolith_deps = [ "vendor:jruby", "vendor:gems", "vendor:elasticsearch", "compile" ]

  namespace :monolith do
    task :tar => monolith_deps do
      paths = %w{ bin CHANGELOG CONTRIBUTORS etc examples Gemfile Gemfile.lock
                  INSTALL lib LICENSE patterns Rakefile README.md STYLE.md test
                  TODO USAGE vendor/bundle vendor/jar }
      sh "tar -zcf logstash-monolithic-someversion.tar.gz #{paths.join(" ")}"
    end # package:monolith:tar

    task :jar => monolith_deps do
      mkdir_p "build-jar"

      # Unpack all the 3rdparty jars
      Dir.glob("vendor/jar/**/*.jar").each do |jar|
        puts "=> Unpacking #{jar} into build-jar/"
        Dir.chdir("build-jar") do 
          sh "jar xf ../#{jar}"
        end
      end

      # We compile stuff to lib/net/logstash/...
      Dir.glob("lib/**/*.class").each do |file|
        target = File.join("build-jar", file.gsub("lib/", ""))
        #target = File.join("build-jar", file)
        mkdir_p File.dirname(target)
        puts "=> Copying #{file} => #{target}"
        File.copy(file, target)
      end

      output = "logstash-#{LOGSTASH_VERSION}.jar"
      sh "jar -cfe #{output} logstash.agent -C build-jar ."
      sh "jar -uf #{output} patterns/"
      sh "jar -i #{output}"
    end # package:monolith:jar
  end # monolith
end # package

task :test do
  sh "cd test; ruby run.rb"
end


# No publishing until 1.0! :)
#task :publish do
  #latest_gem = %x{ls -t logstash-[0-9]*.gem}.split("\n").first
  #sh "gem push #{latest_gem}"
  #latest_lite_gem = %x{ls -t logstash-lite*.gem}.split("\n").first
  #sh "gem push #{latest_lite_gem}"
#end

