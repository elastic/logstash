require 'tempfile'
require 'ftools' # fails in 1.9.2

LOGSTASH_VERSION = "1.0.0" 

# Compile config grammar (ragel -> ruby)
file "lib/logstash/config/grammar.rb" => ["lib/logstash/config/grammar.rl"] do
  sh "make -C lib/logstash/config grammar.rb"
end

# Taken from 'jrubyc' 
#  Currently this code is commented out because jruby emits this:
#     Failure during compilation of file logstash/web/helpers/require_param.rb:
#       java.lang.RuntimeException: java.io.FileNotFoundException: File path
#       /home/jls/projects/logstash/logstash/web/helpers/require_param.rb
#       does not start with parent path /home/jls/projects/logstash/lib
#
#     org/jruby/util/JavaNameMangler.java:105:in `mangleFilenameForClasspath'
#     org/jruby/util/JavaNameMangler.java:32:in `mangleFilenameForClasspath'
#require 'jruby/jrubyc'
##args = [ "-p", "net.logstash" ]
#args = ["-d", "build"]
#args += Dir.glob("**/*.rb")
#status = JRuby::Compiler::compile_argv(args)
#if (status != 0)
  #puts "Compilation FAILED: #{status} error(s) encountered"
  #exit status
#end

task :compile => "lib/logstash/config/grammar.rb" do |t|
  mkdir_p "build"
  sh "rm -rf lib/net"
  Dir.chdir("lib") do
    args = Dir.glob("**/*.rb")
    sh "jrubyc", "-t", "../build", *args
  end
  Dir.chdir("test") do
    args = Dir.glob("**/*.rb")
    sh "jrubyc", "-t", "../build", *args
  end
end

task :jar => [ "package:monolith:jar" ] do |t|
  # Nothing
end

VERSIONS = {
  :jruby => "1.6.0", # Any of CPL1.0/GPL2.0/LGPL2.1 ? Confusing, but OK.
  #:elasticsearch => "0.15.2", # Apache 2.0 license
  :elasticsearch => "0.16.0", # Apache 2.0 license
  :joda => "1.6.2",  # Apache 2.0 license
}

namespace :vendor do
  file "vendor/jar" do |t|
    mkdir_p t.name
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
    sh "bundle install --path #{File.join("vendor", "bundle")}"
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

      # Unpack all the 3rdparty jars and any jars in gems
      Dir.glob("vendor/{bundle,jar}/**/*.jar").each do |jar|
        puts "=> Unpacking #{jar} into build-jar/"
        Dir.chdir("build-jar") do 
          sh "jar xf ../#{jar}"
        end
      end

      # We compile stuff to build/...
      # TODO(sissel): Could probably just use 'jar uf' for this?
      #Dir.glob("build/**/*.class").each do |file|
        #target = File.join("build-jar", file.gsub("build/", ""))
        #mkdir_p File.dirname(target)
        #puts "=> Copying #{file} => #{target}"
        #File.copy(file, target)
      #end

      # Purge any extra files we don't need in META-INF (like manifests and
      # jar signatures)
      ["INDEX.LIST", "MANIFEST.MF", "ECLIPSEF.RSA", "ECLIPSEF.SF"].each do |file|
        File.delete(File.join("build-jar", "META-INF", file)) rescue nil
      end
      #FileUtils.rm_r(File.join("build-jar", "META-INF")) rescue nil

      output = "logstash-#{LOGSTASH_VERSION}-monolithic.jar"
      sh "jar cfe #{output} logstash.runner -C build-jar ."

      jar_update_args = []

      # Learned how to do this mostly from here:
      # http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar
      #
      # Add bundled gems to the jar
      # Skip the 'cache' dir which is just the original .gem files
      gem_dirs = %w{bin doc gems specifications}
      gem_root = File.join(%w{vendor bundle jruby 1.8})
      # for each dir, build args: -C vendor/bundle/jruby/1.8 bin, etc
      gem_jar_args = gem_dirs.collect { |dir| ["-C", gem_root, dir ] }.flatten
      jar_update_args += gem_jar_args

      # Add compiled our compiled ruby code
      jar_update_args += %w{ -C build . }

      # Add web stuff
      jar_update_args += %w{ -C lib logstash/web/public }
      jar_update_args += %w{ -C lib logstash/web/views }

      # Add test code
      #jar_update_args += %w{ -C test logstsah }

      # Add grok patterns
      jar_update_args << "patterns"

      # Update with other files and also build an index.
      sh "jar uf #{output} #{jar_update_args.join(" ")}"
      sh "jar i #{output}"
    end # task package:monolith:jar
  end # namespace monolith

  task :jar => [ "vendor:jruby", "vendor:gems", "compile" ] do
    builddir = "build-jar-thin"
    mkdir_p builddir

    # Unpack jruby
    Dir.glob("vendor/jar/jruby-complete-1.6.0.jar").each do |jar|
      puts "=> Unpacking #{jar} into #{builddir}/"
      Dir.chdir(builddir) do 
        sh "jar xf ../#{jar}"
      end
    end

    ["INDEX.LIST", "MANIFEST.MF", "ECLIPSEF.RSA", "ECLIPSEF.SF"].each do |file|
      File.delete(File.join(builddir, "META-INF", file)) rescue nil
    end

    output = "logstash-#{LOGSTASH_VERSION}.jar"
    sh "jar cfe #{output} logstash.runner -C #{builddir} ."

    jar_update_args = []

    # Learned how to do this mostly from here:
    # http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar
    #
    # Add bundled gems to the jar
    # Skip the 'cache' dir which is just the original .gem files
    gem_dirs = %w{bin doc gems specifications}
    gem_root = File.join(%w{vendor bundle jruby 1.8})
    # for each dir, build args: -C vendor/bundle/jruby/1.8 bin, etc
    gem_jar_args = gem_dirs.collect { |dir| ["-C", gem_root, dir ] }.flatten
    jar_update_args += gem_jar_args

    # Add compiled our compiled ruby code
    jar_update_args += %w{ -C build . }

    # Add web stuff
    jar_update_args += %w{ -C lib logstash/web/public }
    jar_update_args += %w{ -C lib logstash/web/views }

    # Add test code
    #jar_update_args += %w{ -C test logstsah }

    # Add grok patterns
    jar_update_args << "patterns"

    # Update with other files and also build an index.
    sh "jar uf #{output} #{jar_update_args.join(" ")}"
    sh "jar i #{output}"
  end # task package:jar
end # namespace package

task :test do
  sh "cd test; ruby logstash_test_runner.rb"
end

task :docs => [:docgen, :doccopy, :docindex ] do
end

task :require_output_env do
  if ENV["output"].nil?
    raise "No output variable set. Run like: 'rake docs output=path/to/output'"
  end
end

task :doccopy => [:require_output_env] do
  if ENV["output"].nil?
    raise "No output variable set. Run like: 'rake docs output=path/to/output'"
  end

  Dir.glob("docs/**/*").each do |doc|
    dir = File.join(ENV["output"], File.dirname(doc).gsub(/docs\/?/, ""))
    mkdir_p dir
    puts "Copy #{doc} => #{dir}"
    cp(doc, dir)
  end
end

task :docindex => [:require_output_env] do
  sh "ruby docs/generate_index.rb #{ENV["output"]} > #{ENV["output"]}/index.html"
end

task :docgen => [:require_output_env] do
  if ENV["output"].nil?
    raise "No output variable set. Run like: 'rake docgen output=path/to/output'"
  end

  sh "find lib/logstash/inputs lib/logstash/filters lib/logstash/outputs  -type f -not -name 'base.rb' -a -name '*.rb'| xargs ruby docs/docgen.rb -o #{ENV["output"]}"
end


# No publishing until 1.0! :)
#task :publish do
  #latest_gem = %x{ls -t logstash-[0-9]*.gem}.split("\n").first
  #sh "gem push #{latest_gem}"
  #latest_lite_gem = %x{ls -t logstash-lite*.gem}.split("\n").first
  #sh "gem push #{latest_lite_gem}"
#end

