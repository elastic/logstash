require 'tempfile'

task :tar do
  version = ENV["VERSION"]
  version ||= Time.now.strftime "%Y%m%d%H%M%S"
  outdir = ENV["OUTDIR"]
  outdir ||= "/tmp"
  sh "rm -rf /tmp/logstash-build/"
  sh "mkdir -p /tmp/logstasth-build/logstash-#{version}"
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
  sh "cd /tmp/logstash-build && " \
     "tar -czf #{outdir}/logstash-#{version}.tar.gz logstash-#{version}"
end
