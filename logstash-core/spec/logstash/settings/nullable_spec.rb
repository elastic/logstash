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

describe LogStash::Setting::Nullable do
  let(:setting_name) { "this.that" }
  let(:normal_setting) { LogStash::Setting::String.new(setting_name, nil, false, possible_strings) }
  let(:possible_strings) { [] } # empty means any string passes

  subject(:nullable_setting) { normal_setting.nullable }

  it 'is a kind of Nullable' do
    expect(nullable_setting).to be_a_kind_of(described_class)
  end

  it "retains the wrapped setting's name" do
    expect(nullable_setting.name).to eq(setting_name)
  end

  context 'when unset' do
    context '#validate_value' do
      it 'does not error' do
        expect { nullable_setting.validate_value }.to_not raise_error
      end
    end
    context '#set?' do
      it 'is false' do
        expect(nullable_setting.set?).to be false
      end
    end
    context '#value' do
      it 'is nil' do
        expect(nullable_setting.value).to be_nil
      end
    end
  end

  context 'when set' do
    before(:each) { nullable_setting.set(candidate_value) }
    context 'to an invalid wrong-type value' do
      let(:candidate_value) { 127 } # wrong type, expects String
      it 'is an invalid setting' do
        expect { nullable_setting.validate_value }.to raise_error(ArgumentError, a_string_including("Setting \"#{setting_name}\" must be a "))
      end
    end
    context 'to an invalid value not in the allow-list' do
      let(:possible_strings) { %w(this that)}
      let(:candidate_value) { "another" } # wrong type, expects String
      it 'is an invalid setting' do
        expect { nullable_setting.validate_value }.to raise_error(ArgumentError, a_string_including("Invalid value"))
      end
    end
    context 'to a valid value' do
      let(:candidate_value) { "hello" }
      it 'is a valid setting' do
        expect { nullable_setting.validate_value }.to_not raise_error
        expect(nullable_setting.value).to eq candidate_value
      end
    end
  end
end
