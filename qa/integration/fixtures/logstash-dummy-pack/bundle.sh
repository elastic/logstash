bundle install --path vendor
bundle exec rake vendor
bundle exec rake paquet:vendor
rm -rf build/
mkdir -p build/logstash-dummy-pack/logstash/
cp -r dependencies build/logstash-dummy-pack/logstash/
gem build logstash-output-secret.gemspec
mv logstash-output-secret*.gem build/logstash-dummy-pack/logstash/

# Generate stuff for a uber zip
mkdir -p build/logstash-dummy-pack/elasticsearch
touch build/logstash-dummy-pack/elasticsearch/README.md

mkdir -p build/logstash-dummy-pack/kibana
touch build/logstash-dummy-pack/kibana/README.md

cd build/
zip -r logstash-dummy-pack.zip logstash-dummy-pack
cp *.zip ../
cd ..
