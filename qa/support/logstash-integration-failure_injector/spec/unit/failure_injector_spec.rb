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

# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/failure_injector"
require "logstash/outputs/failure_injector"

%w(filter output).each do | plugin_type |
  instance = plugin_type == 'filter' ? LogStash::Filters::FailureInjector : LogStash::Outputs::FailureInjector
  phase = plugin_type == 'filter' ? 'filter' : 'receive'
  describe instance do
    let(:params) { { 'degrade_at' => [], 'crash_at' => nil } }
    let(:event) { LogStash::Event.new }
    let(:plugin) { described_class.new(params) }

    before do
      allow(plugin).to receive(:@logger).and_return(double('logger', :debug => nil, :trace => nil))
    end

    describe 'plugin base' do
      subject { described_class }
      it { is_expected.to be_a_kind_of Class }
      it { is_expected.to be <= (plugin_type == 'filter' ? LogStash::Filters::Base : LogStash::Outputs::Base) }
      it { is_expected.to have_attributes(:config_name => "failure_injector") }
    end

    shared_examples 'a phase that can degrade or crash' do |phase|
      context "when degrades at #{phase}" do
        let(:params) { { 'degrade_at' => [phase] } }

        it 'calls the degrade method' do
          expect(plugin).to receive(:degrade).with(phase)
          case phase
          when 'filter'
            plugin.filter(event)
          when 'receive'
            plugin.multi_receive([event])
          else
            plugin.send(phase)
          end
        end
      end

      context "when crashes at #{phase}" do
        let(:params) { { 'crash_at' => phase } }

        it 'raises a crash error' do
          case phase
          when 'filter'
            expect { plugin.filter(event) }.to raise_error(RuntimeError, /crashing at #{phase}/)
          when 'receive'
            expect { plugin.multi_receive([event]) }.to raise_error(RuntimeError, /crashing at #{phase}/)
          else
            expect { plugin.send(phase) }.to raise_error(RuntimeError, /crashing at #{phase}/)
          end
        end
      end
    end

    describe '#initialize' do
      context 'when valid params are passed' do
        let(:params) { { 'degrade_at' => [], 'crash_at' => nil } }

        it 'does not raise any error' do
          expect { described_class.new(params) }.not_to raise_error
        end
      end

      context 'when invalid params are passed' do
        it 'raises an error on invalid config' do
          configs = ["register", plugin_type == 'filter' ? "filter" : "receive", "close"]
          expect {
            described_class.new('degrade_at' => ['invalid'], 'crash_at' => 'invalid')
          }.to raise_error("failure_injector #{plugin_type} plugin accepts #{configs} configs but received invalid")
        end
      end
    end

    describe '#register' do
      it_behaves_like 'a phase that can degrade or crash', 'register'
    end

    if plugin_type == 'filter'
      describe '#filter' do
        it_behaves_like 'a phase that can degrade or crash', 'filter'
      end
    end

    if plugin_type == 'output'
      describe '#receive' do
        it_behaves_like 'a phase that can degrade or crash', 'receive'
      end
    end

    describe '#close' do
      it_behaves_like 'a phase that can degrade or crash', 'close'
    end

    describe '#degrade' do
      it 'sleeps for a certain period of time' do
        expect(plugin).to receive(:sleep).at_least(:once)
        plugin.degrade('filter')
      end
    end

    describe '#crash' do
      it 'raises an error with the phase' do
        expect { plugin.crash(phase) }.to raise_error(RuntimeError, /crashing at #{phase}/)
      end
    end
  end
end

