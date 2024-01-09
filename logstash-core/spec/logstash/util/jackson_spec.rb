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

describe LogStash::Util::Jackson do
  it 'configures the read constraints defaults' do
    read_constraints_defaults = double('read_constraints_defaults')
    expect(read_constraints_defaults).to receive(:configure)

    expect(LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults).to receive(:new).and_return(read_constraints_defaults)

    LogStash::Util::Jackson.set_jackson_defaults(double('logger').as_null_object)
  end
end

describe LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults do
  let(:logger) { double('logger') }

  subject { described_class.new(logger) }

  shared_examples 'stream read constraint property' do |property|
    let(:property) { property }
    let(:value) { nil }
    let(:builder) { double('builder') }
    let(:builder_set_value_method) { expected_builder_set_value_method(property) }

    before(:each) do
      allow(logger).to receive(:info)

      allow(builder).to receive(:build).and_return(com.fasterxml.jackson.core.StreamReadConstraints::builder.build)
      allow(builder).to receive(builder_set_value_method).with(value.to_i)

      allow(subject).to receive(:new_stream_read_constraints_builder).and_return(builder)
      allow(subject).to receive(:get_property_value) do |name|
        if name == property
          value.to_s
        else
          nil
        end
      end
    end

    context 'with valid number' do
      let(:value) { '10' }
      it 'does not raises an error and set value' do
        expect { subject.configure }.to_not raise_error
        expect(builder).to have_received(builder_set_value_method).with(value.to_i)
      end
    end

    context 'with non-number value' do
      let(:value) { 'foo' }
      it 'raises an error and does not set value' do
        expect { subject.configure }.to raise_error(LogStash::ConfigurationError, /System property '#{property}' must be a positive integer value. Received: #{value}/)
        expect(builder).to_not have_received(builder_set_value_method)
      end
    end

    context 'with zeroed value' do
      let(:value) { '0' }
      it 'raises an error and does not set value' do
        expect { subject.configure }.to raise_error(LogStash::ConfigurationError, /System property '#{property}' must be bigger than zero. Received: #{value}/)
        expect(builder).to_not have_received(builder_set_value_method)
      end
    end

    context 'with zeroed value' do
      let(:value) { '-1' }
      it 'raises an error and does not set value' do
        expect { subject.configure }.to raise_error(LogStash::ConfigurationError, /System property '#{property}' must be bigger than zero. Received: #{value}/)
        expect(builder).to_not have_received(builder_set_value_method)
      end
    end

    def expected_builder_set_value_method(property)
      case property
      when LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_STRING_LENGTH
        return :maxStringLength
      when LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_NUMBER_LENGTH
        return :maxNumberLength
      when LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_NESTING_DEPTH
        return :maxNestingDepth
      else
        raise 'Invalid system property value'
      end
    end
  end

  [
    LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_STRING_LENGTH,
    LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_NUMBER_LENGTH,
    LogStash::Util::Jackson::JacksonStreamReadConstraintsDefaults::PROPERTY_MAX_NESTING_DEPTH,
  ].each { |system_property|
    context "#{system_property}" do
      it_behaves_like "stream read constraint property", system_property
    end
  }
end