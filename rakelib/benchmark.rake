namespace :benchmark do
  desc "Run benchmark code in benchmark/*.rb"
  task :run => ["test:setup"] do
    path = File.join(LogStash::Environment::LOGSTASH_HOME, "tools/benchmark", "*.rb")
    Dir.glob(path).each { |f| require f }
  end
end
task :benchmark => "benchmark:run"
