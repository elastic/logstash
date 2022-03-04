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
require "logstash/settings"
require "logstash/util/cloud_setting_id"
require "logstash/util/cloud_setting_auth"
require "logstash/util/modules_setting_array"
require "java"

describe LogStash::Setting::Modules do
  describe "Modules.Cli" do
    subject { described_class.new("mycloudid", LogStash::Util::ModulesSettingArray, []) }
    context "when given an array of hashes that contains a password key" do
      let(:secret) { 'some_secret'}
      it "should convert password Strings to Password" do
        source = [{"var.kibana.password" => secret}]
        setting = subject.set(source)
        expect(setting).to be_a(java.util.ArrayList)
        expect(setting.class).to eq(LogStash::Util::ModulesSettingArray)
        expect(setting.first.fetch("var.kibana.password")).to be_a(LogStash::Util::Password)
        expect(setting.first.fetch("var.kibana.password").value).to eq(secret)
      end

      it 'should not wrap values that are already passwords' do
        source = [{"var.kibana.password" => LogStash::Util::Password.new(secret)}]
        setting = subject.set(source)
        expect(setting).to be_a(java.util.ArrayList)
        expect(setting.class).to eq(LogStash::Util::ModulesSettingArray)
        expect(setting.first.fetch("var.kibana.password")).to be_a(LogStash::Util::Password)
        expect(setting.first.fetch("var.kibana.password").value).to eq(secret)
      end
    end
  end

  describe "Cloud.Id" do
    subject { described_class.new("mycloudid", LogStash::Util::CloudSettingId) }
    context "when given a string which is not a cloud id" do
      it "should raise an exception" do
        expect { subject.set("foobarbaz") }.to raise_error(ArgumentError, /Cloud Id.*is invalid/)
      end
    end

    context "when given a string which is empty" do
      it "should raise an exception" do
        expect { subject.set("") }.to raise_error(ArgumentError, /Cloud Id.*is invalid/)
      end
    end

    context "when given a string which is has environment prefix only" do
      it "should raise an exception" do
        expect { subject.set("testing:") }.to raise_error(ArgumentError, /Cloud Id.*is invalid/)
      end
    end

    context "when given a badly formatted encoded id" do
      it "should not raise an error" do
        encoded = Base64.urlsafe_encode64("foo$$bal")
        expect { subject.set(encoded) }.to raise_error(ArgumentError, "Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"foo$$bal\".")
      end
    end

    context "when given a nil" do
      it "should not raise an error" do
        expect { subject.set(nil) }.to_not raise_error
      end
    end

    context "when given a string which is an unlabelled cloud id" do
      it "should set a LogStash::Util::CloudId instance" do
        expect { subject.set("dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy") }.to_not raise_error
        expect(subject.value.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
        expect(subject.value.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
        expect(subject.value.label).to eq("")
      end
    end

    context "when given a string which is a labelled cloud id" do
      it "should set a LogStash::Util::CloudId instance" do
        expect { subject.set("staging:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy") }.to_not raise_error
        expect(subject.value.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
        expect(subject.value.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
        expect(subject.value.label).to eq("staging")
      end
    end
  end

  describe "Cloud.Auth" do
    subject { described_class.new("mycloudauth", LogStash::Util::CloudSettingAuth) }
    context "when given a string without a separator or a password" do
      it "should raise an exception" do
        expect { subject.set("foobarbaz") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string without a password" do
      it "should raise an exception" do
        expect { subject.set("foo:") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string without a username" do
      it "should raise an exception" do
        expect { subject.set(":bar") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string which is empty" do
      it "should raise an exception" do
        expect { subject.set("") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a nil" do
      it "should not raise an error" do
        expect { subject.set(nil) }.to_not raise_error
      end
    end

    context "when given a string which is a cloud auth" do
      it "should set the string" do
        expect { subject.set("frodo:baggins") }.to_not raise_error
        expect(subject.value.username).to eq("frodo")
        expect(subject.value.password.value).to eq("baggins")
        expect(subject.value.to_s).to eq("frodo:<password>")
      end
    end
  end
end
