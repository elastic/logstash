# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/elasticsearch_client"
require "logstash/modules/kibana_client"
require "logstash/modules/kibana_config"
require "logstash/modules/scaffold"
require "logstash/modules/elasticsearch_importer"
require "logstash/modules/kibana_importer"

require_relative "../../support/helpers"

describe LogStash::Modules::Scaffold do
  let(:base_dir) { "gem-home" }
  let(:mname) { "foo" }
  subject(:test_module) { described_class.new(mname, base_dir) }
  let(:module_settings) do
    {
      "var.elasticsearch.hosts" => "es.mycloud.com:9200",
      "var.elasticsearch.user" => "foo",
      "var.elasticsearch.password" => "password",
      "var.input.tcp.port" => 5606,
    }
  end
  let(:dashboard_hash) do
    {
      "hits" => 0,
      "timeRestore" => false,
      "description" => "",
      "title" => "Filebeat Apache2 Dashboard",
      "uiStateJSON" => "{}",
      "panelsJSON" => '[{"col":1,"id":"foo-c","panelIndex":1,"row":1,"size_x":12,"size_y":3,"type":"visualization"},{"id":"foo-d","type":"search","panelIndex":7,"size_x":12,"size_y":3,"col":1,"row":11,"columns":["apache2.error.client","apache2.error.level","apache2.error.module","apache2.error.message"],"sort":["@timestamp","desc"]}]',
      "optionsJSON" => "{}",
      "version" => 1,
      "kibanaSavedObjectMeta" => {
        "searchSourceJSON" => "{}"
      }
    }
  end
  let(:viz_hash) do
    {
      "visState" => "",
      "description" => "",
      "title" => "foo-c",
      "uiStateJSON" => "",
      "version" => 1,
      "savedSearchId" => "foo-e",
      "kibanaSavedObjectMeta" => {}
    }
  end
  let(:index_pattern_hash) do
    {
      "title" => "foo-*",
      "timeFieldName" => "time",
      "fieldFormatMap" => "{some map}",
      "fields" => "[some array]"
    }
  end
  context "logstash operation" do
    let(:ls_conf) do
<<-ERB
input {
  tcp {
    port => <%= setting("var.input.tcp.port", 45) %>
    host => <%= setting("var.input.tcp.host", "localhost") %>
    type => <%= setting("var.input.tcp.type", "server") %>
  }
}
filter {

}
output {
  <%= elasticsearch_output_config() %>
}
ERB
    end

    before do
      allow(LogStash::Modules::FileReader).to receive(:read).and_return(ls_conf)
    end

    it "provides a logstash config" do
      expect(test_module.logstash_configuration).to be_nil
      test_module.with_settings(LogStash::Util::ModulesSettingArray.new([module_settings]).first)
      expect(test_module.logstash_configuration).not_to be_nil
      config_string = test_module.config_string
      expect(config_string).to include("port => 5606")
      expect(config_string).to include("hosts => ['es.mycloud.com:9200']")
    end
  end

  context "elasticsearch operation" do
    it "provides the elasticsearch mapping file paths" do
      test_module.with_settings(module_settings)
      expect(test_module.elasticsearch_configuration).not_to be_nil
      files = test_module.elasticsearch_configuration.resources
      expect(files.size).to eq(1)
      expect(files.first).to be_a(LogStash::Modules::ElasticsearchResource)
      expect(files.first.content_path).to eq("gem-home/elasticsearch/foo.json")
      expect(files.first.import_path).to eq("_template/foo")
    end
  end

  context "kibana operation" do
    before do
      # allow(LogStash::Modules::FileReader).to receive(:read_json).and_return({})
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/dashboard/foo.json").and_return(["Foo-Dashboard"])
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/dashboard/Foo-Dashboard.json").and_return(dashboard_hash)
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/visualization/foo-c.json").and_return(viz_hash)
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/search/foo-d.json").and_return({"d" => "search"})
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/search/foo-e.json").and_return({"e" => "search"})
      allow(LogStash::Modules::FileReader).to receive(:read_json).with("gem-home/kibana/6.x/index-pattern/foo.json").and_return(index_pattern_hash)
    end

    it "provides a list of importable files" do
      expect(test_module.kibana_configuration).to be_nil
      test_module.with_settings(module_settings)
      expect(test_module.kibana_configuration).not_to be_nil
      resources = test_module.kibana_configuration.resources
      expect(resources.size).to eq(2)
      resource1 = resources[0]
      resource2 = resources[1]
      expect(resource1).to be_a(LogStash::Modules::KibanaSettings)
      expect(resource2).to be_a(LogStash::Modules::KibanaDashboards)
      expect(resource1.import_path).to eq("api/kibana/settings")
      expect(resource1.content).to be_a(Array)
      expect(resource1.content.size).to eq(1)

      test_object = resource1.content[0]
      expect(test_object).to be_a(LogStash::Modules::KibanaSettings::Setting)
      expect(test_object.name).to eq("defaultIndex")
      expect(test_object.value).to eq("foo-*")

      expect(resource2.import_path).to eq("api/kibana/dashboards/import")
      expect(resource2.content).to be_a(Array)
      expect(resource2.content.size).to eq(5)
      expect(resource2.content.map {|o| o.class}.uniq).to eq([LogStash::Modules::KibanaResource])

      test_object = resource2.content[0]
      expect(test_object.content_id).to eq("foo-*")
      expect(test_object.content_type).to eq("index-pattern")
      expect(test_object.content_as_object).to eq(index_pattern_hash)

      test_object = resource2.content[1]
      expect(test_object.content_id).to eq("Foo-Dashboard")
      expect(test_object.content_type).to eq("dashboard")
      expect(test_object.content_as_object).to eq(dashboard_hash)

      test_object = resource2.content[2]
      expect(test_object.content_id).to eq("foo-c") #<- the panels can contain items from other folders
      expect(test_object.content_type).to eq("visualization")
      expect(test_object.content_as_object).to eq(viz_hash)
      expect(test_object.content_as_object["savedSearchId"]).to eq("foo-e")

      test_object = resource2.content[3]
      expect(test_object.content_id).to eq("foo-d") #<- the panels can contain items from other folders
      expect(test_object.content_type).to eq("search")
      expect(test_object.content_as_object).to eq("d" => "search")

      test_object = resource2.content[4]
      expect(test_object.content_id).to eq("foo-e") # <- the visualization can contain items from the search folder
      expect(test_object.content_type).to eq("search")
      expect(test_object.content_as_object).to eq("e" => "search")
    end
  end

  context "importing to elasticsearch stubbed client" do
    let(:mname) { "tester" }
    let(:base_dir) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "modules_test_files", "modules", "#{mname}", "configuration")) }
    let(:response) { double(:response) }
    let(:client) { double(:client) }
    let(:kbnclient) { double(:kbnclient) }
    let(:paths) { [] }
    let(:expected_paths) { ["_template/tester", "api/kibana/settings", "api/kibana/dashboards/import"] }
    let(:contents) { [] }
    let(:expected_objects) do
      [
        "index-pattern tester-*",
        "dashboard FW-Dashboard",
        "visualization FW-Viz-1",
        "visualization FW-Viz-2",
        "search Search-Tester"
      ]
    end

    before do
      allow(response).to receive(:status).and_return(404)
      allow(client).to receive(:head).and_return(response)
      allow(kbnclient).to receive(:version).and_return("9.8.7-6")
    end

    it "calls the import method" do
      expect(client).to receive(:put).once do |path, content|
        paths << path
        LogStash::ElasticsearchClient::Response.new(201, "", {})
      end
      expect(kbnclient).to receive(:post).twice do |path, content|
        paths << path
        contents << content
        LogStash::Modules::KibanaClient::Response.new(201, "", {})
      end
      test_module.with_settings(module_settings)
      test_module.import(LogStash::Modules::ElasticsearchImporter.new(client), LogStash::Modules::KibanaImporter.new(kbnclient))
      expect(paths).to eq(expected_paths)
      expect(contents[0]).to eq({"changes" => {"defaultIndex" => "tester-*"}})
      second_kbn_post = contents[1]
      expect(second_kbn_post[:version]).to eq("9.8.7-6")
      expect(second_kbn_post[:objects]).to be_a(Array)
      expect(second_kbn_post[:objects].size).to eq(5)
      objects_types_ids = second_kbn_post[:objects].map {|h| "#{h["type"]} #{h["id"]}"}
      expect(objects_types_ids).to eq(expected_objects)
    end
  end

  context "import 4 realz", :skip => "integration" do
    let(:mname) { "cef" }
    let(:base_dir) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "modules_test_files", "#{mname}")) }
    let(:module_settings) do
      {
        "var.elasticsearch.hosts" => "localhost:9200",
        "var.elasticsearch.user" => "foo",
        "var.elasticsearch.password" => "password",
        "var.input.tcp.port" => 5606,
      }
    end
    it "puts stuff in ES" do
      test_module.with_settings(module_settings)
      client = LogStash::ElasticsearchClient.build(module_settings)
      import_engine = LogStash::Modules::Importer.new(client)
      test_module.import(import_engine)
      expect(1).to eq(1)
    end
  end
end
