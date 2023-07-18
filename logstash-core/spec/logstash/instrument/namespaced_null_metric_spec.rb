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
require "spec_helper"

describe LogStash::Instrument::NamespacedNullMetric do
  let(:namespace) { :root }
  let(:collector) { [] }
  let(:metric) { LogStash::Instrument::NullMetric.new(collector) }

  subject { described_class.new(metric, namespace) }

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::NamespacedMetric)
  end

  it "returns a TimedException when we call without a block" do
    expect(subject.time(:duration_ms)).to be_kind_of(LogStash::Instrument::NullMetric::NullTimedExecution)
  end

  it "returns the value of the block" do
    expect(subject.time(:duration_ms) { "hello" }).to eq("hello")
  end

  it "its doesnt change the original `namespace` when creating a subnamespace" do
    new_namespace = subject.namespace(:wally)

    expect(subject.namespace_name).to eq([namespace])
    expect(new_namespace.namespace_name).to eq([:root, :wally])
  end
end
