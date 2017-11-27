require_relative "../../../lib/bootstrap/environment"

if $0 == __FILE__
  LogStash::Bundler.setup!({:without => [:build, :development]})
  require "logstash/namespace"
  require_relative "../../../lib/bootstrap/patches/jar_dependencies"
  require "logstash/dependency_report"

  exit_status = LogStash::DependencyReport.run 
  exit(exit_status || 0)
end
