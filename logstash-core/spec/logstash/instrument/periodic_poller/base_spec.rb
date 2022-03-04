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

require "logstash/instrument/periodic_poller/base"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::Base do
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }
  let(:options) { {} }

  subject { described_class.new(metric, options) }

  describe "#update" do
    it "logs an timeout exception to debug level" do
      exception = Concurrent::TimeoutError.new
      expect(subject.logger).to receive(:debug).with(anything, hash_including(:exception => exception.class))
      subject.update(Time.now, "hola", exception)
    end

    it "logs any other exception to error level" do
      exception = Class.new
      expect(subject.logger).to receive(:error).with(anything, hash_including(:exception => exception.class))
      subject.update(Time.now, "hola", exception)
    end

    it "doesnt log anything when no exception is received" do
      exception = Concurrent::TimeoutError.new
      expect(subject.logger).not_to receive(:debug).with(anything)
      expect(subject.logger).not_to receive(:error).with(anything)
      subject.update(Time.now, "hola", exception)
    end
  end
end
