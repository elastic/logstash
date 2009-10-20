task :tar do
  version = ENV["VERSION"]
  version ||= Time.now.strftime "%Y%m%d%H%M%S"
  sh "rm -rf /tmp/logstash-build/"
  sh "mkdir -p /tmp/logstasth-build/logstash-#{version}"
  sh "svn export https://logstash.googlecode.com/svn/trunk " \
     "/tmp/logstash-build/logstash-#{version}"
  sh "cd /tmp/logstash-build && " \
     "tar -czf /tmp/logstash-#{version}.tar.gz logstash-#{version}"
end
