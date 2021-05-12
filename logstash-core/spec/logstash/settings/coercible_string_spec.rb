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

describe LogStash::Setting::CoercibleString do
  let(:setting_name) { "example" }
  let(:supported_values) { %w(a b c) }
  let(:default_value) { supported_values.first }
  let(:deprecated_alias_mapping) { Hash.new.freeze }

  subject(:coercible_setting) { described_class.new(setting_name, default_value, true, supported_values, deprecated_alias_mapping) }

  describe "#set" do
    context "when a deprecated alias is provided" do
      let(:deprecated_alias_mapping) { {proposed_value => expected_result} }
      let(:proposed_value) { "z" }
      let(:expected_result) { "c" }

      let(:deprecation_logger_stub) { double('DeprecationLogger').as_null_object }

      before(:each) do
        allow(coercible_setting).to receive(:deprecation_logger).and_return(deprecation_logger_stub)
      end

      it 'resolves the deprecated alias to the valid value' do
        coercible_setting.set(proposed_value)

        aggregate_failures do
          expect(coercible_setting).to be_set
          expect(coercible_setting).to have_attributes(value: expected_result)
          expect(deprecation_logger_stub).to have_received(:deprecated).with(/is deprecated and may not be supported/)
        end
      end
    end

    context "when a supported coercible value is provided" do
      let(:proposed_value) { :b }

      it 'rejects the invalid value' do
        coercible_setting.set(proposed_value)

        aggregate_failures do
          expect(coercible_setting).to be_set
          expect(coercible_setting).to have_attributes(value: "b")
        end
      end
    end

    context "when an unsupported value is provided" do
      let(:proposed_value) { "XXX" }

      it 'rejects the invalid value' do
        aggregate_failures do
          expect { coercible_setting.set(proposed_value) }.to raise_error(ArgumentError, /Invalid value/)
          expect(coercible_setting).to_not be_set
          expect(coercible_setting).to have_attributes(value: default_value)
        end
      end
    end
  end
end
