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

require_relative "../../support/matchers"
require_relative "../../support/shared_examples"
require "spec_helper"

describe LogStash::Instrument::NamespacedMetric do
  let(:namespace) { :root }
  let(:collector) { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }

  subject { described_class.new(metric, namespace) }

  before(:each) { allow(collector).to receive(:push).and_call_original }

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::Metric)
  end

  it "returns a TimedException when we call without a block" do
    expect(subject.time(:duration_ms)).to be_kind_of(LogStash::Instrument::Metric::TimedExecution)
  end

  it "returns the value of the block" do
    expect(subject.time(:duration_ms) { "hello" }).to eq("hello")
  end

  it "its doesnt change the original `namespace` when creating a subnamespace" do
    new_namespace = subject.namespace(:wally)

    expect(subject.namespace_name).to eq([namespace])
    expect(new_namespace.namespace_name).to eq([:root, :wally])
  end

  context "#increment" do
    it "a counter by 1" do
      subject.increment(:error_rate)
      expect(collector).to have_received(:push).with([:root], :error_rate, :counter, :increment, 1)
    end

    it "a counter by a provided value" do
      subject.increment(:error_rate, 20)
      expect(collector).to have_received(:push).with([:root], :error_rate, :counter, :increment, 20)
    end
  end

  context "#decrement", skip: "LongCounter impl does not support decrement" do
    it "a counter by 1" do
      subject.decrement(:error_rate)
      expect(collector).to have_received(:push).with([:root], :error_rate, :counter, :decrement, 1)
    end

    it "a counter by a provided value" do
      subject.decrement(:error_rate, 20)
      expect(collector).to have_received(:push).with([:root], :error_rate, :counter, :decrement, 20)
    end
  end

  context "#gauge" do
    it "set the value of a key" do
      subject.gauge(:size_queue, 20)
      expect(collector).to have_received(:push).with([:root], :size_queue, :gauge, :set, 20)
    end
  end

  context "#time" do
    let(:sleep_time) { 2 }
    let(:sleep_time_ms) { sleep_time * 1_000 }

    it "records the duration" do
      subject.time(:duration_ms) { sleep(sleep_time) }

      timer = metric.timer(namespace, :duration_ms)
      expect(timer.value).to be_within(50).of(sleep_time_ms)
    end

    it "return a TimedExecution" do
      execution = subject.time(:duration_ms)
      sleep(sleep_time)

      timer = metric.timer(namespace, :duration_ms)
      expect(timer.value).to eq(0) # no live tracking without a block

      execution_time = execution.stop

      expect(execution_time).to be_within(50).of(sleep_time_ms)
      expect(timer.value).to be_within(50).of(sleep_time_ms)
    end
  end

  context "#namespace" do
    let(:namespace) { [:deeply, :nested] }
    let(:sub_key) { [:even, :deeper] }

    it "creates a new metric object and append the `sub_key` to the `base_key`" do
      expect(subject.namespace(sub_key).namespace_name).to eq(namespace + sub_key)
    end

    it "uses the same collector as the creator class" do
      child = subject.namespace(sub_key)
      child.increment(:error_rate)
      expect(collector).to have_received(:push).with((namespace + sub_key), :error_rate, :counter, :increment, 1)
    end
  end

  include_examples "metrics commons operations"
end
