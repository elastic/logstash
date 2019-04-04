# encoding: utf-8

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
        before(:each) { instance.set(:foo, 'bananas') }

        it 'sets the new value' do
          instance.set(:foo, 'bar')
          expect(instance.get(:foo)).to eq('bar')
        end
        it 'returns the previous associated value' do
          expect(instance.set(:foo, 'bar')).to eq('bananas')
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
  end
end