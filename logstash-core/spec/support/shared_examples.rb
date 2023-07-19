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

# Define the common operation that both the `NullMetric` class and the Namespaced class should answer.
shared_examples "metrics commons operations" do
  let(:key) { "galaxy" }

  describe "#increment" do
    it "allows to increment a key with no amount" do
      expect { subject.increment(key, 100) }.not_to raise_error
    end

    it "allow to increment a key" do
      expect { subject.increment(key) }.not_to raise_error
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.increment("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.increment(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  describe "#decrement", skip: "LongCounter impl does not support decrement" do
    it "allows to decrement a key with no amount" do
      expect { subject.decrement(key, 100) }.not_to raise_error
    end

    it "allow to decrement a key" do
      expect { subject.decrement(key) }.not_to raise_error
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.decrement("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.decrement(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  describe "#gauge" do
    it "allows to set a value" do
      expect { subject.gauge(key, "pluto") }.not_to raise_error
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.gauge("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.gauge(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  describe "#report_time" do
    it "allow to record time" do
      expect { subject.report_time(key, 1000) }.not_to raise_error
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.report_time("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.report_time(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  describe "#time" do
    it "allow to record time with a block given" do
      expect do
        subject.time(key) { 1 + 1 }
      end.not_to raise_error
    end

    it "returns the value of the block without recording any metrics" do
      expect(subject.time(:execution_time) { "hello" }).to eq("hello")
    end

    it "return a TimedExecution" do
      execution = subject.time(:do_something)
      expect { execution.stop }.not_to raise_error
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.time("") {} }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.time(nil) {} }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end
end

shared_examples "not found" do
  it "should return a 404 to unknown request" do
    get "/i_want_to_believe-#{Time.now.to_i}"
    expect(last_response.content_type).to eq("application/json")
    expect(last_response).not_to be_ok
    expect(last_response.status).to eq(404)
    expect(LogStash::Json.load(last_response.body)).to include("status" => 404)
    expect(LogStash::Json.load(last_response.body)["path"]).not_to be_nil
  end
end
