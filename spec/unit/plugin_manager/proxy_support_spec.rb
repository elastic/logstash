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

require "pluginmanager/proxy_support"
require "rexml/document"
require "fileutils"
require "uri"

describe "Proxy support" do
  let(:settings) { File.join(Dir.home, ".m2", "settings.xml") }
  let(:settings_backup) { "#{settings}_bk" }

  before do
    FileUtils.mv(settings, settings_backup) if File.exist?(settings)
    environments.each { |key, value| ENV[key] = value }
  end

  after do
    FileUtils.mv(settings_backup, settings) if File.exist?(settings_backup)
    environments.each { |key, _| ENV[key] = nil }
  end

  shared_examples "proxy access" do
    let(:http_proxy) { "http://a:b@local.dev:9898" }
    let(:https_proxy) { "https://c:d@local.dev:9898" }
    let(:http_proxy_uri) { URI(http_proxy) }
    let(:https_proxy_uri) { URI(https_proxy) }
    let(:schemes) { ["http", "https"]}

    let(:environments) {
      {
        "HTTP_PROXY" => http_proxy,
        "HTTPS_PROXY" => https_proxy
      }
    }

    after do
      ["http", "https"].each do |scheme|
        java.lang.System.clearProperty("#{scheme}.proxyHost")
        java.lang.System.clearProperty("#{scheme}.proxyPort")
        java.lang.System.clearProperty("#{scheme}.proxyUsername")
        java.lang.System.clearProperty("#{scheme}.proxyPassword")
      end
    end

    it "updates the java proxy properties" do
      # asserts the changes
      schemes.each do |scheme|
        expect(java.lang.System.getProperty("#{scheme}.proxyHost")).to be_nil
        expect(java.lang.System.getProperty("#{scheme}.proxyPort")).to be_nil
        expect(java.lang.System.getProperty("#{scheme}.proxyUsername")).to be_nil
        expect(java.lang.System.getProperty("#{scheme}.proxyPassword")).to be_nil
      end

      configure_proxy

      schemes.each do |scheme|
        expect(java.lang.System.getProperty("#{scheme}.proxyHost")).to eq(send("#{scheme}_proxy_uri").host)
        expect(java.lang.System.getProperty("#{scheme}.proxyPort")).to eq(send("#{scheme}_proxy_uri").port.to_s)
        expect(java.lang.System.getProperty("#{scheme}.proxyUsername")).to eq(send("#{scheme}_proxy_uri").user)
        expect(java.lang.System.getProperty("#{scheme}.proxyPassword")).to eq(send("#{scheme}_proxy_uri").password)
      end
    end

    context "when the $HOME/.m2/settings.xml doesn't exist" do
      it "creates the settings files" do
        expect(File.exist?(settings)).to be_falsey
        configure_proxy
        expect(File.exist?(settings)).to be_truthy
      end

      it "defines the proxies in the xml file" do
        configure_proxy

        content = REXML::Document.new(File.read(settings))

        schemes.each_with_index do |scheme, idx|
          target = idx + 1
          expect(REXML::XPath.first(content, "//proxy[#{target}]/active/text()")).to be_truthy
          expect(REXML::XPath.first(content, "//proxy[#{target}]/port/text()")).to eq(send("#{scheme}_proxy_uri").port)
          expect(REXML::XPath.first(content, "//proxy[#{target}]/host/text()")).to eq(send("#{scheme}_proxy_uri").host)
          expect(REXML::XPath.first(content, "//proxy[#{target}]/username/text()")).to eq(send("#{scheme}_proxy_uri").user)
          expect(REXML::XPath.first(content, "//proxy[#{target}]/password/text()")).to eq(send("#{scheme}_proxy_uri").password)
        end
      end
    end

    context "when the $HOME/.m2/settings.xml exists" do
      let(:dummy_settings) { "<settings></settings>" }

      before do
        File.open(settings, "w") do |f|
          f.write(dummy_settings)
        end
      end

      it "doesn't do anything to to the original file" do
        expect(File.read(settings)).to eq(dummy_settings)
        configure_proxy
        expect(File.read(settings)).to eq(dummy_settings)
      end
    end
  end

  context "when `HTTP_PROXY` and `HTTPS_PROXY` are configured" do
    include_examples "proxy access"
  end

  context "when `http_proxy` and `https_proxy` are configured" do
    include_examples "proxy access" do
      let(:environments) {
        {
          "http_proxy" => http_proxy,
          "https_proxy" => https_proxy
        }
      }
    end
  end

  context "when proxies are set with an empty string" do
    let(:environments) {
      {
        "http_proxy" => "",
        "https_proxy" => ""
      }
    }

    it "doesn't raise an exception" do
      expect { configure_proxy }.not_to raise_exception
    end
  end

  context "when proxies are set to invalid values" do
    let(:environments) {
      {
        "http_proxy" => "myproxy:8080",   # missing scheme
        "https_proxy" => "myproxy:8080"
      }
    }

    it "raises an exception" do
      expect { configure_proxy }.to raise_error(RuntimeError)
    end
  end
end
