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

require 'spec_helper'
require 'logstash/settings'

describe LogStash::Setting::StringArray do
  let(:value) { [] }
  let(:strict) { true }
  let(:possible_strings) { nil }

  subject { described_class.new('testing', value, strict, possible_strings) }

  context 'when given a coercible string' do
    context 'with 1 element' do
      let(:value) { %w[hello] }

      it 'returns 1 element' do
        expect(subject.value).to match(%w[hello])
      end
    end

    context 'with multiple elements' do
      let(:value) { %w[hello ninja] }

      it 'returns an array of strings' do
        expect(subject.value).to match(value)
      end
    end
  end

  context 'when defining possible_strings' do
    let(:possible_strings) { %w[foo bar] }
    let(:value) { %w[bar foo] }

    context 'when a single given value is not a possible_strings' do
      it 'should raise an ArgumentError' do
        expect { subject.set(%w[foo baz]) }.to raise_error(ArgumentError, "Failed to validate the setting \"#{subject.name}\" value(s): [\"baz\"]. Valid options are: #{possible_strings.inspect}")
      end
    end

    context 'when multiple given values are not a possible_strings' do
      it 'should raise an ArgumentError' do
        expect { subject.set(%w[foo baz boot]) }.to raise_error(ArgumentError, "Failed to validate the setting \"#{subject.name}\" value(s): [\"baz\", \"boot\"]. Valid options are: #{possible_strings.inspect}")
      end
    end
  end
end
