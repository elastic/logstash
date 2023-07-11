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

describe LogStash::Setting::SplittableStringArray do
  let(:default_value) { ['default'] }

  subject { described_class.new('testing', default_value) }

  before do
    subject.set(candidate)
  end

  context "when giving an array" do
    let(:candidate) { ["hello,", "ninja"] }

    it "returns the same elements" do
      expect(subject.value).to match(candidate)
    end
  end

  context "when given a string" do
    context "with 1 element" do
      let(:candidate) { "hello" }

      it "returns 1 element" do
        expect(subject.value).to match(["hello"])
      end
    end

    context "with multiple element" do
      let(:candidate) { "hello,ninja" }

      it "returns an array of string" do
        expect(subject.value).to match(["hello", "ninja"])
      end
    end
  end

  context 'when defining a custom tokenizer' do
    let(:default_value) { [] }
    let(:possible_strings) { [] }
    subject { described_class.new('testing', default_value, strict=true, possible_strings, ';') }

    let(:candidate) { 'hello;ninja' }

    it 'returns an array of string' do
      expect(subject.value).to match(%w[hello ninja])
    end
  end

  context 'when defining allowed values' do
    let(:default_value) { [] }
    let(:possible_strings) { %w[foo bar] }
    subject { described_class.new('testing', [], strict=true, possible_strings) }

    let(:candidate) { 'bar, foo' }

    it 'returns an array of string' do
      expect(subject.value).to eql %w[bar foo]
    end

    it 'setting a valid array value' do
      expect { subject.set(%w[bar foo]) }.to_not raise_error(ArgumentError)
    end

    context 'when a single given value is not a possible_strings' do
      it 'should raise an ArgumentError' do
        expect { subject.set('foo,baz') }.to raise_error(ArgumentError, "Failed to validate the setting \"#{subject.name}\" value(s): [\"baz\"]. Valid options are: #{possible_strings.inspect}")
      end
    end

    context 'when multiple given values are not a possible_strings' do
      it 'should raise an ArgumentError' do
        expect { subject.set('foo,baz,boot') }.to raise_error(ArgumentError, "Failed to validate the setting \"#{subject.name}\" value(s): [\"baz\", \"boot\"]. Valid options are: #{possible_strings.inspect}")
      end
    end
  end
end
