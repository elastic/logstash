#encoding: utf-8
require 'spec_helper'
require 'pluginmanager/util'
require 'gems'

describe LogStash::PluginManager do

  describe "fetching plugin information" do
    let(:plugin_name) { "logstash-output-elasticsearch" }

    let(:version_data) do
      [ { "authors"=>"Elastic", "built_at"=>"2015-08-11T00:00:00.000Z", "description"=>"Output events to elasticsearch",
          "downloads_count"=>1638, "metadata"=>{"logstash_group"=>"output", "logstash_plugin"=>"true"}, "number"=>"2.0.0.pre",
          "summary"=>"Logstash Output to Elasticsearch", "platform"=>"java", "ruby_version"=>">= 0", "prerelease"=>true,
          "licenses"=>["apache-2.0"], "requirements"=>[], "sha"=>"194b27099c13605a882a3669e2363fdecccaab1de48dd44b0cda648dd5516799"},
      { "authors"=>"Elastic", "built_at"=>"2015-08-10T00:00:00.000Z", "description"=>"Output events to elasticsearch",
        "downloads_count"=>1638, "metadata"=>{"logstash_group"=>"output", "logstash_plugin"=>"true"}, "number"=>"1.0.7",
        "summary"=>"Logstash Output to Elasticsearch", "platform"=>"java", "ruby_version"=>">= 0", "prerelease"=>false,
        "licenses"=>["apache-2.0"], "requirements"=>[], "sha"=>"194b27099c13605a882a3669e2363fdecccaab1de48dd44b0cda648dd5516799"},
      { "authors"=>"Elastic", "built_at"=>"2015-08-09T00:00:00.000Z", "description"=>"Output events to elasticsearch",
        "downloads_count"=>1638, "metadata"=>{"logstash_group"=>"output", "logstash_plugin"=>"true"}, "number"=>"1.0.4",
        "summary"=>"Logstash Output to Elasticsearch", "platform"=>"java", "ruby_version"=>">= 0", "prerelease"=>false,
        "licenses"=>["apache-2.0"], "requirements"=>[], "sha"=>"194b27099c13605a882a3669e2363fdecccaab1de48dd44b0cda648dd5516799"} ]
    end

    before(:each) do
      allow(Gems).to receive(:versions).with(plugin_name).and_return(version_data)
    end

    context "fetch plugin info" do
      it "should search for the last version infomation non prerelease" do
        version_info = LogStash::PluginManager.fetch_latest_version_info(plugin_name)
        expect(version_info["number"]).to eq("1.0.7")
      end


      it "should search for the last version infomation with prerelease" do
        version_info = LogStash::PluginManager.fetch_latest_version_info(plugin_name, :pre => true)
        expect(version_info["number"]).to eq("2.0.0.pre")
      end
    end
  end

  describe "a logstash_plugin validation" do
    let(:plugin)  { "foo" }
    let(:version) { "9.0.0.0" }

    let(:sources) { ["http://source.01", "http://source.02"] }
    let(:options) { {:rubygems_source => sources} }

    let(:gemset)  { double("gemset") }
    let(:gemfile) { double("gemfile") }
    let(:dep)     { double("dep") }
    let(:fetcher) { double("fetcher") }

    before(:each) do
      allow(gemfile).to  receive(:gemset).and_return(gemset)
      allow(gemset).to   receive(:sources).and_return(sources)
      expect(fetcher).to receive(:spec_for_dependency).and_return([[],[]])
    end

    it "should load all available sources" do
      expect(subject).to receive(:plugin_file?).and_return(false)
      expect(Gem::Dependency).to receive(:new).and_return(dep)
      expect(Gem::SpecFetcher).to receive(:fetcher).and_return(fetcher)

      subject.logstash_plugin?(plugin, version, options)
      expect(Gem.sources.map { |source| source }).to eq(sources)
    end
  end
end
