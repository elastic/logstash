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

describe LogStash::Setting::Integer do
  subject { described_class.new("a number", nil, false) }
  describe "#set" do
    context "when giving a number which is not an integer" do
      it "should raise an exception" do
        expect { subject.set(1.1) }.to raise_error(ArgumentError)
      end
    end
    context "when giving a number which is an integer" do
      it "should set the number" do
        expect { subject.set(100) }.to_not raise_error
        expect(subject.value).to eq(100)
      end
    end
  end
end
