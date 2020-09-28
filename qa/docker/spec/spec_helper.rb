ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
$LOAD_PATH.unshift File.join(ROOT, 'logstash-core/lib')
FIXTURES_DIR = File.expand_path(File.join("..", "..", "fixtures"), __FILE__)

require 'logstash/version'
require 'json'
require 'stud/try'
require 'docker-api'

def version
  @version ||= LOGSTASH_VERSION
end

def qualified_version
  qualifier = ENV['VERSION_QUALIFIER']
  qualified_version = qualifier ? [version, qualifier].join("-") : version
  ENV["RELEASE"] == "1" ? qualified_version : [qualified_version, "SNAPSHOT"].join("-")
end

def find_image(flavor)
  Docker::Image.all.detect{
      |image| image.info['RepoTags'].detect{
        |tag| tag == "docker.elastic.co/logstash/logstash-#{flavor}:#{qualified_version}"
    }}
end

def create_container(image, options = {})
  image.run(nil, options)
end

def start_container(image, options={})
  container = create_container(image, options)
  wait_for_logstash(container)
  container
end

def wait_for_logstash(container)
  Stud.try(40.times, RSpec::Expectations::ExpectationNotMetError) do
    expect(container.exec(['curl', '-s', 'http://localhost:9600/_node'])[0][0]).not_to be_empty
  end
end

def cleanup_container(container)
  unless container.nil?
    container.kill
    container.delete(:force=>true)
  end
end

def license_label_for_flavor(flavor)
  flavor.match(/oss/) ? 'Apache 2.0' : 'Elastic License'
end

def license_agreement_for_flavor(flavor)
  flavor.match(/oss/) ? 'Apache License' : 'ELASTIC LICENSE AGREEMENT!'
end

def get_logstash_status(container)
  JSON.parse(container.exec(['curl', '-s', 'http://localhost:9600'])[0][0])['status']
end


def get_node_info(container)
  JSON.parse(container.exec(['curl', '-s', 'http://localhost:9600/_node'])[0][0])
end

def get_node_stats(container)
  JSON.parse(container.exec(['curl', '-s', 'http://localhost:9600/_node/stats'])[0][0])
end

def get_settings(container)
  YAML.load(container.read_file('/usr/share/logstash/config/logstash.yml'))
end

def java_process(container, column)
  exec_in_container(container, "ps -C java -o #{column}=").strip
end

def exec_in_container(container, command)
  container.exec(command.split)[0].join
end

def architecture_for_flavor(flavor)
  flavor.match(/aarch64/) ? 'arm64' : 'amd64'
end

RSpec::Matchers.define :have_correct_license_label do |expected|
  match do |actual|
    values_match? license_label_for_flavor(expected), actual
  end
  failure_message do |actual|
    "expected License:#{actual} to eq #{license_label_for_flavor(expected)}"
  end
end

RSpec::Matchers.define :have_correct_license_agreement do |expected|
  match do |actual|
    values_match? /#{license_agreement_for_flavor(expected)}/, actual
    true
  end
  failure_message do |actual|
    "expected License Agreement:#{actual} to contain #{license_agreement_for_flavor(expected)}"
  end
end

RSpec::Matchers.define :have_correct_architecture_for_flavor do |expected|
  match do |actual|
    values_match? architecture_for_flavor(expected), actual
    true
  end
  failure_message do |actual|
    "expected Architecture: #{actual} to be #{architecture_for_flavor(expected)}"
  end
end

shared_context 'image_context' do |flavor|
  before do
    @image = find_image(flavor)
    @image_config = @image.json['Config']
    @labels = @image_config['Labels']
  end
end
