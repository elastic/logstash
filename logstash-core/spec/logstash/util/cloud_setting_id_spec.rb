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

require "spec_helper"
require "logstash/util/cloud_setting_id"

describe LogStash::Util::CloudSettingId do
  let(:input) { "foobar:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy" }
  subject { described_class.new(input) }

  describe "when given unacceptable input" do
    it "a nil input does not raise an exception" do
      expect {described_class.new(nil)}.not_to raise_exception
    end
    it "when given a nil input, the accessors are all nil" do
      cloud_id = described_class.new(nil)
      expect(cloud_id.original).to be_nil
      expect(cloud_id.decoded).to be_nil
      expect(cloud_id.label).to be_nil
      expect(cloud_id.elasticsearch_host).to be_nil
      expect(cloud_id.kibana_host).to be_nil
      expect(cloud_id.elasticsearch_scheme).to be_nil
      expect(cloud_id.kibana_scheme).to be_nil
    end

    context "when a malformed value is given" do
      let(:raw) {%w(first second)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect {subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{raw[0]}$#{raw[1]}\".")
      end
    end

    context "when at least one segment is empty" do
      let(:raw) {["first", "", "third"]}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect {subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{raw[0]}$#{raw[1]}$#{raw[2]}\".")
      end
    end

    context "when elasticsearch segment is undefined" do
      let(:raw) {%w(us-east-1.aws.found.io undefined my-kibana)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect {subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.")
      end
    end

    context "when kibana segment is undefined" do
      let(:raw) {%w(us-east-1.aws.found.io my-elastic-cluster undefined)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect {subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.")
      end
    end
  end

  describe "without a label" do
    let(:input) { "dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy" }
    it "#label is empty" do
      expect(subject.label).to be_empty
    end
    it "#decode is set" do
      expect(subject.decoded).to eq("us-east-1.aws.found.io$notareal$identifier")
    end
  end

  describe "when given acceptable input, the accessors:" do
    it '#original has a value' do
      expect(subject.original).to eq(input)
    end
    it '#decoded has a value' do
      expect(subject.decoded).to eq("us-east-1.aws.found.io$notareal$identifier")
    end
    it '#label has a value' do
      expect(subject.label).to eq("foobar")
    end
    it '#elasticsearch_host has a value' do
      expect(subject.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
    end
    it '#elasticsearch_scheme has a value' do
      expect(subject.elasticsearch_scheme).to eq("https")
    end
    it '#kibana_host has a value' do
      expect(subject.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
    end
    it '#kibana_scheme has a value' do
      expect(subject.kibana_scheme).to eq("https")
    end
    it '#to_s has a value of #decoded' do
      expect(subject.to_s).to eq(subject.decoded)
    end
  end
  context "when cloud id contains port descriptions for ES and Kibana" do
    let(:input) { "different-es-kb-port:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2OjkyNDMkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA6OTI0NA==" }

    it "decodes the elasticsearch port corretly" do
      expect(subject.elasticsearch_host).to eq("ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243")
    end
    it "decodes the kibana port corretly" do
      expect(subject.kibana_host).to eq("a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244")
    end
  end
  context "when cloud id contains cloud port" do
    let(:input) { "custom-port:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvOjkyNDMkYWMzMWViYjkwMjQxNzczMTU3MDQzYzM0ZmQyNmZkNDYkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA=" }

    it "decodes the elasticsearch port corretly" do
      expect(subject.elasticsearch_host).to eq("ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243")
    end
    it "decodes the kibana port corretly" do
      expect(subject.kibana_host).to eq("a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9243")
    end
  end
  context "when cloud id only defines kibana port" do
    let(:input) { "only-kb-set:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2JGE0YzA2MjMwZTQ4YzhmY2U3YmU4OGEwNzRhM2JiM2UwOjkyNDQ=" }

    it "defaults the elasticsearch port to 443" do
      expect(subject.elasticsearch_host).to eq("ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:443")
    end
    it "decodes the kibana port corretly" do
      expect(subject.kibana_host).to eq("a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244")
    end
  end
  context "when cloud id defines cloud port and kibana port" do
    let(:input) { "host-and-kb-set:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvOjkyNDMkYWMzMWViYjkwMjQxNzczMTU3MDQzYzM0ZmQyNmZkNDYkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA6OTI0NA==" }

    it "sets the elasticsearch port to cloud port" do
      expect(subject.elasticsearch_host).to eq("ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243")
    end
    it "overrides cloud port with the kibana port" do
      expect(subject.kibana_host).to eq("a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244")
    end
  end
  context "when cloud id defines extra data" do
    let(:input) { "extra-items:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2JGE0YzA2MjMwZTQ4YzhmY2U3YmU4OGEwNzRhM2JiM2UwJGFub3RoZXJpZCRhbmRhbm90aGVy" }

    it "captures the elasticsearch host" do
      expect(subject.elasticsearch_host).to eq("ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:443")
    end
    it "captures the kibana host" do
      expect(subject.kibana_host).to eq("a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:443")
    end
    it "captures the remaining identifiers" do
      expect(subject.other_identifiers).to eq(["anotherid", "andanother"])
    end
  end

  describe "when given acceptable input (with empty kibana uuid), the accessors:" do
    let(:input) { "a-test:ZWNlLmhvbWUubGFuJHRlc3Qk" } # ece.home.lan$test$

    it '#original has a value' do
      expect(subject.original).to eq(input)
    end
    it '#decoded has a value' do
      expect(subject.decoded).to eq("ece.home.lan$test$")
    end
    it '#label has a value' do
      expect(subject.label).to eq("a-test")
    end
    it '#elasticsearch_host has a value' do
      expect(subject.elasticsearch_host).to eq("test.ece.home.lan:443")
    end
    it '#elasticsearch_scheme has a value' do
      expect(subject.elasticsearch_scheme).to eq("https")
    end
    it '#kibana_host has a value' do
      # NOTE: kibana part is not relevant -> this is how python/beats(go) code behaves
      expect(subject.kibana_host).to eq(".ece.home.lan:443")
    end
    it '#kibana_scheme has a value' do
      expect(subject.kibana_scheme).to eq("https")
    end
    it '#to_s has a value of #decoded' do
      expect(subject.to_s).to eq(subject.decoded)
    end
  end

  describe "a lengthy real-world input, the accessors:" do
    let(:input) do
      "ZWFzdHVzMi5henVyZS5lbGFzdGljLWNsb3VkLmNvbTo5MjQzJDQwYjM0MzExNmNmYTRlYmNiNzZjMTFlZTIzMjlmOTJkJDQzZDA5MjUyNTAyYzQxODlhMzc2ZmQwY2YyY2QwODQ4"
      # eastus2.azure.elastic-cloud.com:9243$40b343116cfa4ebcb76c11ee2329f92d$43d09252502c4189a376fd0cf2cd0848
    end

    it '#original has a value' do
      expect(subject.original).to eq(input)
    end
    it '#decoded has a value' do
      expect(subject.decoded).to eq("eastus2.azure.elastic-cloud.com:9243$40b343116cfa4ebcb76c11ee2329f92d$43d09252502c4189a376fd0cf2cd0848")
    end
    it '#label has a value' do
      expect(subject.label).to eq("")
    end
    it '#elasticsearch_host has a value' do
      expect(subject.elasticsearch_host).to eq("40b343116cfa4ebcb76c11ee2329f92d.eastus2.azure.elastic-cloud.com:9243")
    end
    it '#kibana_host has a value' do
      expect(subject.kibana_host).to eq("43d09252502c4189a376fd0cf2cd0848.eastus2.azure.elastic-cloud.com:9243")
    end
    it '#to_s has a value of #decoded' do
      expect(subject.to_s).to eq(subject.decoded)
    end
  end
end
