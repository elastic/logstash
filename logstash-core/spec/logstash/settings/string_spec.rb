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

describe LogStash::Setting::String do
  let(:possible_values) { ["a", "b", "c"] }
  subject { described_class.new("mytext", possible_values.first, true, possible_values) }
  describe "#set" do
    context "when a value is given outside of possible_values" do
      it "should raise an ArgumentError" do
        expect { subject.set("d") }.to raise_error(ArgumentError)
      end
    end
    context "when a value is given within possible_values" do
      it "should set the value" do
        expect { subject.set("a") }.to_not raise_error
        expect(subject.value).to eq("a")
      end
    end
  end
end
