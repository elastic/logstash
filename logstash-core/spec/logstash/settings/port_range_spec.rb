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

require "logstash/settings"
require "spec_helper"

describe LogStash::Setting::PortRange do
  context "When the value is an Integer" do
    subject { LogStash::Setting::PortRange.new("mynewtest", 9000) }

    it "coerces the value in a range" do
      expect { subject }.not_to raise_error
    end

    it "returns a range" do
      expect(subject.value).to eq(9000..9000)
    end

    it "can update the range" do
      subject.set(10000)
      expect(subject.value).to eq(10000..10000)
    end
  end

  context "When the value is a string" do
    subject { LogStash::Setting::PortRange.new("mynewtest", "9000-10000") }

    it "coerces a string range with the format (9000-10000)" do
      expect { subject }.not_to raise_error
    end

    it "refuses when then upper port is out of range" do
      expect { LogStash::Setting::PortRange.new("mynewtest", "1000-95000") }.to raise_error
    end

    it "returns a range" do
      expect(subject.value).to eq(9000..10000)
    end

    it "can update the range" do
      subject.set("500-1000")
      expect(subject.value).to eq(500..1000)
    end
  end

  context "when the value is a garbage string" do
    subject { LogStash::Setting::PortRange.new("mynewtest", "fsdfnsdkjnfjs") }

    it "raises an argument error" do
      expect { subject }.to raise_error
    end

    it "raises an exception on update" do
      expect { LogStash::Setting::PortRange.new("mynewtest", 10000).set("dsfnsdknfksdnfjksdnfjns") }.to raise_error
    end
  end

  context "when the value is an unknown type" do
    subject { LogStash::Setting::PortRange.new("mynewtest", 0.1) }

    it "raises an argument error" do
      expect { subject }.to raise_error
    end

    it "raises an exception on update" do
      expect { LogStash::Setting::PortRange.new("mynewtest", 10000).set(0.1) }.to raise_error
    end
  end

  context "When value is a range" do
    subject { LogStash::Setting::PortRange.new("mynewtest", 9000..10000) }

    it "accepts a ruby range as the default value" do
      expect { subject }.not_to raise_error
    end

    it "can update the range" do
      subject.set(500..1000)
      expect(subject.value).to eq(500..1000)
    end

    it "refuses when then upper port is out of range" do
      expect { LogStash::Setting::PortRange.new("mynewtest", 9000..1000000) }.to raise_error
    end

    it "raise an exception on when port are out of range" do
      expect { LogStash::Setting::PortRange.new("mynewtest", -1000..1000) }.to raise_error
    end
  end
end
