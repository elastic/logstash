require "spec_helper"

require "logstash/plugin"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

describe LogStash::Plugins::EventFactorySupport do
  let(:event_factory_support) { described_class }

  [
      LogStash::Inputs::Base,
      LogStash::Filters::Base,
      LogStash::Codecs::Base,
      LogStash::Outputs::Base
  ].each do |base_class|
    context "that inherits from `#{base_class}`" do
      let(:plugin_base_class) { base_class }

      subject(:plugin_class) do
        Class.new(plugin_base_class) do
          config_name 'sample'
        end
      end

      it 'defines an `event_factory` method' do
        expect(plugin_class.method_defined?(:event_factory)).to be true
      end

      it 'defines an `targeted_event_factory` method' do
        expect(plugin_class.method_defined?(:targeted_event_factory)).to be true
      end

      let(:options) { Hash.new }
      let(:plugin) { plugin_class.new(options) }

      shared_examples 'an event factory' do
        it 'returns an event' do
          expect(event_factory.new_event).to be_a LogStash::Event
          expect(event = event_factory.new_event('foo' => 'bar')).to be_a LogStash::Event
          expect(event.get('foo')).to eql 'bar'
        end
      end

      describe 'event_factory' do
        subject(:event_factory) { plugin.send(:event_factory) }

        it_behaves_like 'an event factory'

        it 'memoizes the factory instance' do
          expect(event_factory).to be plugin.send(:event_factory)
        end
      end

      describe 'targeted_event_factory (no config :target option)' do
        it 'raises an error' do
          expect { plugin.send(:targeted_event_factory) }.to raise_error(ArgumentError, /target/)
        end
      end

      describe 'targeted_event_factory' do
        subject(:plugin_class) do
          Class.new(plugin_base_class) do
            config_name 'sample'

            config :target, :validate => :string
          end
        end

        subject(:targeted_event_factory) { plugin.send(:targeted_event_factory) }

        it_behaves_like 'an event factory' do
          subject(:event_factory) { targeted_event_factory }
        end

        it 'memoizes the factory instance' do
          expect(targeted_event_factory).to be plugin.send(:targeted_event_factory)
        end

        it 'uses the basic event factory (no target specified)' do
          expect(targeted_event_factory).to be plugin.send(:event_factory)
        end

        context 'with target' do
          let(:options) { super().merge('target' => '[the][baz]') }

          it 'returns an event' do
            expect(targeted_event_factory.new_event).to be_a LogStash::Event
            expect(event = targeted_event_factory.new_event('foo' => 'bar')).to be_a LogStash::Event
            expect(event.include?('foo')).to be false
            expect(event.get('[the][baz][foo]')).to eql 'bar'
          end

          it 'memoizes the factory instance' do
            expect(targeted_event_factory).to be plugin.send(:targeted_event_factory)
          end

          it 'uses a different factory from the basic one' do
            expect(targeted_event_factory).not_to be plugin.send(:event_factory)
          end
        end

        context 'from_json (integration)' do
          let(:json) { '[ {"foo": "bar"}, { "baz": { "a": 1 } } ]' }

          let(:options) { super().merge('target' => 'internal') }

          it 'works' do
            events = LogStash::Event.from_json(json) { |data| targeted_event_factory.new_event(data) }
            expect(events.size).to eql 2
            expect(events[0].get('[internal]')).to eql 'foo' => 'bar'
            expect(events[1].get('[internal]')).to eql 'baz' => { 'a' => 1 }
          end
        end
      end
    end
  end
end
