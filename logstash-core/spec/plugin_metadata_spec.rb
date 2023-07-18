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
require 'logstash/plugin_metadata'
require 'securerandom'

describe LogStash::PluginMetadata do
  let(:registry) { described_class }
  before(:each) { registry.reset! }

  let(:plugin_id) { SecureRandom.uuid }

  describe 'registry' do
    describe '#for_plugin' do
      it 'returns the same instance when given the same id' do
        expect(registry.for_plugin(plugin_id)).to be(registry.for_plugin(plugin_id))
      end
      it 'returns different instances when given different ids' do
        expect(registry.for_plugin(plugin_id)).to_not equal(registry.for_plugin(plugin_id.next))
      end
    end
    describe '#exists?' do
      context 'when the plugin has not yet been registered' do
        it 'returns false' do
          expect(registry.exists?(plugin_id)).to be false
        end
      end
      context 'when the plugin has already been registered' do
        before(:each) { registry.for_plugin(plugin_id).set(:foo, 'bar') }
        it 'returns true' do
          expect(registry.exists?(plugin_id)).to be true
        end
      end
    end
    describe '#delete_for_plugin' do
      before(:each) { registry.for_plugin(plugin_id).set(:foo, 'bar') }
      it 'deletes the registry' do
        expect(registry.exists?(plugin_id)).to be true
        registry.delete_for_plugin(plugin_id)
        expect(registry.exists?(plugin_id)).to be false
      end
      it 'deletes the data inside the registry' do
        plugin_registry = registry.for_plugin(plugin_id)
        registry.delete_for_plugin(plugin_id)
        expect(plugin_registry.set?(:foo)).to be false
      end
    end
  end

  describe 'instance' do
    let(:instance) { registry.for_plugin(plugin_id) }

    describe '#set' do
      context 'when the key is not set' do
        it 'sets the new value' do
          instance.set(:foo, 'bar')
          expect(instance.get(:foo)).to eq('bar')
        end
        it 'returns the nil' do
          expect(instance.set(:foo, 'bar')).to be_nil
        end
      end
      context 'when the key is set' do
        let (:val) { 'bananas'}
        before(:each) { instance.set(:foo, val) }

        it 'sets the new value' do
          instance.set(:foo, 'bar')
          expect(instance.get(:foo)).to eq('bar')
        end
        it 'returns the previous associated value' do
          expect(instance.set(:foo, 'bar')).to eq(val)
        end
        context 'when the new value is nil' do
          it 'unsets the value' do
            instance.set(:foo, nil)
            expect(instance.set?(:foo)).to be false
          end
        end
      end
    end

    describe '#get' do
      context 'when the key is set' do
        before(:each) { instance.set(:foo, 'bananas') }
        it 'returns the associated value' do
          expect(instance.get(:foo)).to eq('bananas')
        end
      end
      context 'when the key is not set' do
        it 'returns nil' do
          expect(instance.get(:foo)).to be_nil
        end
      end
    end

    describe '#set?' do
      context 'when the key is set' do
        before(:each) { instance.set(:foo, 'bananas')}
        it 'returns true' do
          expect(instance.set?(:foo)).to be true
        end
      end
      context 'when the key is not set' do
        it 'returns false' do
          expect(instance.set?(:foo)).to be false
        end
      end
    end

    describe '#delete' do
      context 'when the key is set' do
        let (:val) { 'bananas' }
        before(:each) { instance.set(:foo, val)}
        it 'returns the value' do
          expect(instance.delete(:foo)).to be val
        end
        it 'removes the key' do
          instance.delete(:foo)
          expect(instance.set?(:foo)).to be false
        end
      end
      context 'when the key is not set' do
        it 'returns nil' do
          expect(instance.delete(:foo)).to be nil
        end

        it 'should not be set' do
          instance.delete(:foo)
          expect(instance.set?(:foo)).to be false
        end
      end
    end

    describe '#clear' do
      context 'when the key is set' do
        before(:each) do
          instance.set(:foo, 'bananas')
          instance.set(:bar, 'more bananas')
        end
        it 'removes all keys' do
          instance.clear
          expect(instance.set?(:foo)).to be false
          expect(instance.set?(:bar)).to be false
        end
      end
    end
  end
end
