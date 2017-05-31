# encoding: utf-8
#
require "logstash/namespace"
require "logstash/modules/scaffold"
require "logstash/modules/importer"
require "logstash/elasticsearch_client"

require_relative "../../support/helpers"

describe LogStash::Modules::Scaffold do
  let(:base_dir) { "gem-home" }
  let(:mname) { "foo" }
  subject(:test_module) { described_class.new(mname, base_dir) }
  let(:module_settings) do
    {
      "var.output.elasticsearch.hosts" => "es.mycloud.com:9200",
      "var.output.elasticsearch.user" => "foo",
      "var.output.elasticsearch.password" => "password",
      "var.input.tcp.port" => 5606,
      "dashboards.kibana_index" => ".kibana"
    }
  end
  let(:dashboard_json) do
<<-JSON
{
"hits": 0,
"timeRestore": false,
"description": "",
"title": "Filebeat Apache2 Dashboard",
"uiStateJSON": "{\\"P-1\\":{\\"mapCenter\\":[40.713955826286046,-0.17578125]}}",
"panelsJSON": "[{\\"col\\":1,\\"id\\":\\"foo-c\\",\\"panelIndex\\":1,\\"row\\":1,\\"size_x\\":12,\\"size_y\\":3,\\"type\\":\\"visualization\\"},{\\"col\\":1,\\"id\\":\\"foo-d\\",\\"panelIndex\\":2,\\"row\\":6,\\"size_x\\":8,\\"size_y\\":3,\\"type\\":\\"visualization\\"},{\\"id\\":\\"foo-e\\",\\"type\\":\\"search\\",\\"panelIndex\\":7,\\"size_x\\":12,\\"size_y\\":3,\\"col\\":1,\\"row\\":11,\\"columns\\":[\\"apache2.error.client\\",\\"apache2.error.level\\",\\"apache2.error.module\\",\\"apache2.error.message\\"],\\"sort\\":[\\"@timestamp\\",\\"desc\\"]}]",
"optionsJSON": "{\\"darkTheme\\":false}",
"version": 1,
"kibanaSavedObjectMeta": {
  "searchSourceJSON": "{\\"filter\\":[{\\"query\\":{\\"query_string\\":{\\"analyze_wildcard\\":true,\\"query\\":\\"*\\"}}}]}"
}
}
JSON
  end
  let(:viz_json) do
<<-JSON
{
"visState": "",
"description": "",
"title": "foo-c",
"uiStateJSON": "",
"version": 1,
"savedSearchId": "foo-f",
"kibanaSavedObjectMeta": {}
}
JSON
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
      test_module.with_settings(module_settings)
      expect(test_module.logstash_configuration).not_to be_nil
      config_string = test_module.config_string
      expect(config_string).to include("port => 5606")
      expect(config_string).to include('hosts => ["es.mycloud.com:9200"]')
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
      allow(LogStash::Modules::FileReader).to receive(:read).and_return("{}")
      allow(LogStash::Modules::FileReader).to receive(:read).with("gem-home/kibana/dashboard/foo.json").and_return("[\"Foo-Dashboard\"]")
      allow(LogStash::Modules::FileReader).to receive(:read).with("gem-home/kibana/dashboard/Foo-Dashboard.json").and_return(dashboard_json)
      allow(LogStash::Modules::FileReader).to receive(:read).with("gem-home/kibana/visualization/foo-c.json").and_return(viz_json)
    end

    it "provides a list of importable files" do
      expect(test_module.kibana_configuration).to be_nil
      test_module.with_settings(module_settings)
      expect(test_module.kibana_configuration).not_to be_nil
      files = test_module.kibana_configuration.resources
      expect(files.size).to eq(7)
      expect(files.map{|o| o.class.name}.uniq).to eq(["LogStash::Modules::KibanaResource"])
      expect(files[0].content_path).to eq("gem-home/kibana/index_pattern/foo.json")
      expect(files[0].import_path).to eq(".kibana/index-pattern/foo-*")

      expect(files[1].content).to eq("{\"defaultIndex\": \"\#{pattern_name}\"}")
      expect(files[1].import_path).to eq(".kibana/config/5.4.0")

      expect(files[2].content_path).to eq("gem-home/kibana/dashboard/Foo-Dashboard.json")
      expect(files[2].import_path).to eq(".kibana/dashboard/Foo-Dashboard")
      expect(files[3].content_path).to eq("gem-home/kibana/visualization/foo-c.json")
      expect(files[3].import_path).to eq(".kibana/visualization/foo-c")
      expect(files[4].content_path).to eq("gem-home/kibana/visualization/foo-d.json")
      expect(files[4].import_path).to eq(".kibana/visualization/foo-d")
      expect(files[5].content_path).to eq("gem-home/kibana/search/foo-e.json") #<- the panels can contain items from other folders
      expect(files[5].import_path).to eq(".kibana/search/foo-e")
      expect(files[6].content_path).to eq("gem-home/kibana/search/foo-f.json") #<- the visualization can contain items from the search folder
      expect(files[6].import_path).to eq(".kibana/search/foo-f")
    end

    it "provides the kibana index string" do
      test_module.with_settings(module_settings)
      expect(test_module.kibana_configuration).not_to be_nil
      expect(test_module.kibana_configuration.index_name).to eq(".kibana")
    end
  end

  context "importing to elasticsearch stubbed client" do
    let(:mname) { "cef" }
    let(:base_dir) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "modules_test_files", "#{mname}")) }
    let(:response) { double(:response) }
    let(:client) { double(:client) }
    let(:paths) { [] }
    let(:expected_paths) do
      [
        "_template/cef",
        ".kibana/index-pattern/cef-*",
        ".kibana/config/5.4.0",
        ".kibana/dashboard/FW-Dashboard",
        ".kibana/visualization/FW-Metrics",
        ".kibana/visualization/FW-Last-Update",
        ".kibana/visualization/FW-Area-by-Outcome",
        ".kibana/visualization/FW-Count-by-Source,-Destination-Address-and-Ports",
        ".kibana/visualization/FW-Traffic-by-Outcome",
        ".kibana/visualization/FW-Device-Vendor-by-Category-Outcome",
        ".kibana/visualization/FW-Geo-Traffic-by-Destination-Address",
        ".kibana/visualization/FW-Geo-Traffic-by-Source-Address",
        ".kibana/visualization/FW-Destination-Country-Data-Table",
        ".kibana/visualization/FW-Source-Country-Data-Table",
        ".kibana/visualization/FW-Destination-Ports-by-Outcome",
        ".kibana/visualization/FW-Source,-Destination-Address-and-Port-Sunburst",
        ".kibana/search/Firewall-Events"
      ]
    end

    before do
      allow(response).to receive(:status).and_return(404)
      allow(client).to receive(:head).and_return(response)
    end

    it "calls the import method" do
      expect(client).to receive(:put).at_least(15).times do |path, content|
        paths << path
        LogStash::ElasticsearchClient::Response.new(201, "", {})
      end
      test_module.with_settings(module_settings)
      test_module.import(LogStash::Modules::Importer.new(client))
      expect(paths).to eq(expected_paths)
    end
  end

  context "import 4 realz", :skip => "integration" do
    let(:mname) { "cef" }
    let(:base_dir) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "modules_test_files", "#{mname}")) }
    let(:module_settings) do
      {
        "var.output.elasticsearch.hosts" => "localhost:9200",
        "var.output.elasticsearch.user" => "foo",
        "var.output.elasticsearch.password" => "password",
        "var.input.tcp.port" => 5606,
        "dashboards.kibana_index" => ".kibana"
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
