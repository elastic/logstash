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

describe LogStash::Setting::Password do
  let(:setting_name) { "secure" }
  subject(:password_setting) { described_class.new(setting_name, nil, true) }

  context 'when unset' do
    it 'is valid' do
      expect { password_setting.validate_value }.to_not raise_error
      expect(password_setting.value).to be_a_kind_of LogStash::Util::Password
      expect(password_setting.value.value).to be_nil
    end
    context '#set?' do
      it 'returns false' do
        expect(password_setting.set?).to be false
      end
    end
  end

  context 'when set' do
    let(:setting_value) { "s3cUr3p4$$w0rd" }
    before(:each) { password_setting.set(setting_value) }

    it 'is valid' do
      expect { password_setting.validate_value }.to_not raise_error
      expect(password_setting.value).to be_a_kind_of LogStash::Util::Password
      expect(password_setting.value.value).to eq setting_value
    end
    context '#set?' do
      it 'returns true' do
        expect(password_setting.set?).to be true
      end
    end
  end

  context '#set' do
    context 'with an invalid non-string value' do
      let(:setting_value) { 867_5309 }
      it 'rejects the invalid value' do
        expect { password_setting.set(setting_value) }.to raise_error(ArgumentError, "Setting `#{setting_name}` could not coerce non-string value to password")
        expect(password_setting).to_not be_set
      end
    end
  end
end
