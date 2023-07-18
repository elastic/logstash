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
require "logstash/config/cpu_core_strategy"

describe LogStash::Config::CpuCoreStrategy do
  before do
    allow(LogStash::Config::Defaults).to receive(:cpu_cores).and_return(cores)
  end

  context 'when the machine has 6 cores' do
    let(:cores) { 6 }

    it ".maximum should return 6" do
      expect(described_class.maximum).to eq(6)
    end

    it ".fifty_percent should return 3" do
      expect(described_class.fifty_percent).to eq(3)
    end

    it ".seventy_five_percent should return 4" do
      expect(described_class.seventy_five_percent).to eq(4)
    end

    it ".twenty_five_percent should return 1" do
      expect(described_class.twenty_five_percent).to eq(1)
    end

    it ".max_minus_one should return 5" do
      expect(described_class.max_minus_one).to eq(5)
    end

    it ".max_minus_two should return 4" do
      expect(described_class.max_minus_two).to eq(4)
    end
  end

  context 'when the machine has 4 cores' do
    let(:cores) { 4 }

    it ".maximum should return 4" do
      expect(described_class.maximum).to eq(4)
    end

    it ".fifty_percent should return 2" do
      expect(described_class.fifty_percent).to eq(2)
    end

    it ".seventy_five_percent should return 3" do
      expect(described_class.seventy_five_percent).to eq(3)
    end

    it ".twenty_five_percent should return 1" do
      expect(described_class.twenty_five_percent).to eq(1)
    end

    it ".max_minus_one should return 3" do
      expect(described_class.max_minus_one).to eq(3)
    end

    it ".max_minus_two should return 2" do
      expect(described_class.max_minus_two).to eq(2)
    end
  end

  context 'when the machine has 2 cores' do
    let(:cores) { 2 }

    it ".maximum should return 2" do
      expect(described_class.maximum).to eq(2)
    end

    it ".fifty_percent should return 1" do
      expect(described_class.fifty_percent).to eq(1)
    end

    it ".seventy_five_percent should return 1" do
      expect(described_class.seventy_five_percent).to eq(1)
    end

    it ".twenty_five_percent should return 1" do
      expect(described_class.twenty_five_percent).to eq(1)
    end

    it ".max_minus_one should return 1" do
      expect(described_class.max_minus_one).to eq(1)
    end

    it ".max_minus_two should return 1" do
      expect(described_class.max_minus_two).to eq(1)
    end
  end

  context 'when the machine has 1 core' do
    let(:cores) { 1 }

    it ".maximum should return 1" do
      expect(described_class.maximum).to eq(1)
    end

    it ".fifty_percent should return 1" do
      expect(described_class.fifty_percent).to eq(1)
    end

    it ".seventy_five_percent should return 1" do
      expect(described_class.seventy_five_percent).to eq(1)
    end

    it ".twenty_five_percent should return 1" do
      expect(described_class.twenty_five_percent).to eq(1)
    end

    it ".max_minus_one should return 1" do
      expect(described_class.max_minus_one).to eq(1)
    end

    it ".max_minus_two should return 1" do
      expect(described_class.max_minus_two).to eq(1)
    end
  end
end
