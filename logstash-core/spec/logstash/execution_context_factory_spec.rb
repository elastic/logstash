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

describe LogStash::Plugins::ExecutionContextFactory do
  let(:pipeline) { double('Pipeline') }
  let(:agent) { double('Agent') }
  let(:inner_dlq_writer) { nil }

  subject(:factory) { described_class.new(agent, pipeline, inner_dlq_writer) }

  context '#create' do
    let(:plugin_id) { SecureRandom.uuid }
    let(:plugin_type) { 'input' }

    context 'the resulting instance' do
      subject(:instance) { factory.create(plugin_id, plugin_type) }

      it 'retains the pipeline from the factory' do
        expect(instance.pipeline).to be(pipeline)
      end

      it 'retains the agent from the factory' do
        expect(instance.agent).to be(agent)
      end

      it 'has a dlq_writer' do
        expect(instance.dlq_writer).to_not be_nil
      end

      context 'dlq_writer' do
        subject(:instance_dlq_writer) { instance.dlq_writer }

        it 'retains the plugin id' do
          expect(instance_dlq_writer.plugin_id).to eq(plugin_id)
        end

        it 'retains the plugin type' do
          expect(instance_dlq_writer.plugin_type).to eq(plugin_type)
        end
      end
    end
  end
end
