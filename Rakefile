require 'tempfile'

# Compile config grammar (ragel -> ruby)
file "lib/logstash/config/grammar.rb" => ["lib/logstash/config/grammar.rl"] do
  sh "make -C lib/logstash/config grammar.rb"
end

VERSIONS = {
  :jruby => "1.6.0",
  :elasticsearch => "0.15.2",
  :joda => "1.6.2",
}

namespace :vendor do
  file "vendor/jar" do |t|
    Dir.mkdir(t.name)
  end

  # Download jruby.jar
  file "vendor/jar/jruby-complete-#{VERSIONS[:jruby]}.jar" => "vendor/jar" do |t|
    baseurl = "http://repository.codehaus.org/org/jruby/jruby-complete"
    sh "wget -O #{t.name} #{baseurl}/#{VERSIONS[:jruby]}/#{File.basename(t.name)}"
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

  namespace :monolith do
    task :tar => [ "vendor:jruby", "vendor:gems", "vendor:elasticsearch" ] do
      paths = %w{ bin CHANGELOG CONTRIBUTORS etc examples Gemfile Gemfile.lock
                  INSTALL lib LICENSE patterns Rakefile README.md STYLE.md test
                  TODO USAGE vendor/bundle vendor/jar }
      sh "tar -zcf logstash-monolithic-someversion.tar.gz #{paths.join(" ")}"
    end
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

