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

describe LogStash::Setting::Bytes do
  let(:multipliers) do
    {
      "b" => 1,
      "kb" => 1 << 10,
      "mb" => 1 << 20,
      "gb" => 1 << 30,
      "tb" => 1 << 40,
      "pb" => 1 << 50,
    }
  end

  let(:number) { Flores::Random.number(0..1000) }
  let(:unit) { Flores::Random.item(multipliers.keys) }
  let(:default) { "0b" }

  subject { described_class.new("a byte value", default, false) }

  describe "#set" do
    # Hard-coded test just to make sure at least one known case is working
    context "when given '10mb'" do
      it "returns 10485760" do
        expect(subject.set("10mb")).to be == 10485760
      end
    end

    context "when given a string" do
      context "which is a valid byte unit" do
        let(:text) { "#{number}#{unit}" }

        before { subject.set(text) }

        it "should coerce it to an Integer" do
          expect(subject.value).to be_a(::Integer)
        end
      end

      context "which is not a valid byte unit" do
        values = ["hello world", "1234", "", "-__-"]
        values.each do |value|
          it "should fail" do
            expect { subject.set(value) }.to raise_error
          end
        end
      end
    end
  end
end
