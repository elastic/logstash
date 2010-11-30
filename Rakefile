require 'tempfile'

task :package do
  system("gem build logstash.gemspec")
  system("gem build logstash-lite.gemspec")
end

task :publish do
  latest_gem = %x{ls -t logstash-[0-9]*.gem}.split("\n").first
  system("gem push #{latest_gem}")
  latest_lite_gem = %x{ls -t logstash-lite*.gem}.split("\n").first
  system("gem push #{latest_lite_gem}")
end

task :test do
    system("cd test; ruby run.rb")
end

