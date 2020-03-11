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

require "logstash/util/byte_value"
require "flores/random"

describe LogStash::Util::ByteValue do
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

  let(:number) { Flores::Random.number(0..100000000000) }
  let(:unit) { Flores::Random.item(multipliers.keys) }
  let(:text) { "#{number}#{unit}" }

  describe "#parse" do
    # Expect a whole-unit byte value. Fractions of a byte don't make sense here. :)
    let(:expected) { (number * multipliers[unit]).to_i }
    subject { described_class.parse(text) }

    it "should return a Numeric" do
      expect(subject).to be_a(Numeric)
    end

    it "should have an expected byte value" do
      expect(subject).to be == expected
    end
  end
end
