echo "Running integration tests from qa\integration directory"
cd qa\integration
bundle install
rspec specs\01_logstash_bin_smoke_spec.rb
