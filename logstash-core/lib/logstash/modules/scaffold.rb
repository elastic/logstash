# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "erb"

require_relative "elasticsearch_config"
require_relative "kibana_config"
require_relative "logstash_config"

module LogStash module Modules class Scaffold
  include LogStash::Util::Loggable

  attr_reader :directory, :module_name, :logstash_configuration, :kibana_configuration, :elasticsearch_configuration

  def initialize(name, directory)
    @module_name = name
    @directory = directory  # this is the 'configuration folder in the GEM root.'
  end

  def import(import_engine)
    @elasticsearch_configuration.resources.each do |resource|
      import_engine.put(resource)
    end
    @kibana_configuration.resources.each do |resource|
      import_engine.put(resource)
    end
  end

  def with_settings(module_settings)
    @logstash_configuration = LogStashConfig.new(self, module_settings)
    @kibana_configuration = KibanaConfig.new(self, module_settings)
    @elasticsearch_configuration = ElasticsearchConfig.new(self, module_settings)
    self
  end

  def config_string()
    # settings should be set earlier by the caller.
    # settings should be the subset from the YAML file with a structure like
    # {"name" => "plugin name", "k1" => "v1", "k2" => "v2"}, etc.
    return nil if @logstash_configuration.nil?
    @logstash_configuration.config_string
  end
end end end # class LogStash::Modules::Scaffold

# LogStash::PLUGIN_REGISTRY.add(:modules, "example", LogStash::Modules::Scaffold.new("example", File.join(File.dirname(__FILE__), "..", "configuration"))

__END__

settings logstash.yml
modules:
  - name: netflow
  var.output.elasticsearch.host: "es.mycloud.com"
  var.output.elasticsearch.user: "foo"
  var.output.elasticsearch.password: "password"
  var.input.tcp.port: 5606

File structure
logstash-module-netflow
├── configuration
│   ├── elasticsearch
│   │   └── netflow.json
│   ├── kibana
│   │   ├── dashboard
│   │   │   └── netflow.json ("panelJSON" contains references to visualization panels 1,2,3)
│   │   ├── search
|   |   |   └── netflow-search1.json
|   |   |   └── netflow-search2.json
│   │   └── vizualization
|   |   |   └── netflow-panel1.json
|   |   |   └── netflow-panel2.json
|   |   |   └── netflow-panel3.json
│   └── logstash
│       └── netflow.conf.erb
├── lib
│   ├── logstash
│   │   └── modules
│   │       └── netflow.rb
│   └── logstash_registry.rb
└── logstash-module-netflow.gemspec
