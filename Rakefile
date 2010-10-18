require 'tempfile'

MAJOR=0
def mkversion
  rev = %x{svn info | awk '/^Revision:/ { print $NF }'}.split("\n").first.chomp
  return "#{MAJOR}.#{rev}"
end

task :tar do
  version = ENV["VERSION"]
  version ||= mkversion
  outdir = ENV["OUTDIR"]
  outdir ||= "/tmp"
  sh "rm -rf /tmp/logstash-build/"
  sh "mkdir -p /tmp/logstash-build"
  sh "svn export https://logstash.googlecode.com/svn/trunk " \
     "/tmp/logstash-build/logstash-#{version}"
  sh "svn export https://logstash.googlecode.com/svn/wiki " \
     "/tmp/logstash-build/logstash-#{version}/docs"

  # prepend wiki info to all *.wiki exported doc files
  Dir.glob("/tmp/logstash-build/logstash-#{version}/docs/*.wiki").each do |w|
    name = w.split(/\.wiki/).first
    Tempfile.open(File.basename(w)) do |tmpf|
      tmpf << "# The latest version of this doc can be found on the wiki:\n"
      tmpf << "#   http://code.google.com/p/logstash/wiki/#{name}\n\n"
      File.open(w, "r+") do |file|
        tmpf << file.read
        file.pos = tmpf.pos = 0
        file << tmpf.read
      end
    end
  end
  sh "sed -i -e 's/^Version:.*/Version: #{version}/' /tmp/logstash-build/logstash-#{version}/etc/redhat/logstash.spec"
  sh "cd /tmp/logstash-build && " \
     "tar -czf #{outdir}/logstash-#{version}.tar.gz logstash-#{version}"
end

task :package do
  system("gem build logstash.gemspec")
end

task :publish do
  latest_gem = %x{ls -t logstash*.gem}.split("\n").first
  system("gem push #{latest_gem}")
end

