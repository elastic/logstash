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

require "logstash/timer_task"

describe LogStash::TimerTask do
  class RecordingObserver
    attr_reader :notifications

    def initialize
      @notifications = Concurrent::Array.new
    end

    def update(time, result, exception)
      @notifications << [time, result, exception]
    end
  end

  let(:observer) { RecordingObserver.new }

  def wait_for_notification(timeout = 5)
    deadline = Time.now + timeout
    sleep(0.05) while observer.notifications.empty? && Time.now < deadline
    observer.notifications.first
  end

  it "raises when constructed without a block" do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  context "when the task completes within the timeout" do
    subject do
      described_class.new(:execution_interval => 0.1, :timeout_interval => 5) { :done }
    end

    after { subject.shutdown }

    it "notifies observers with the result and no exception" do
      subject.add_observer(observer)
      subject.execute

      _time, result, exception = wait_for_notification
      expect(result).to eq(:done)
      expect(exception).to be_nil
    end
  end

  context "when the task raises" do
    subject do
      described_class.new(:execution_interval => 0.1, :timeout_interval => 5) { raise "boom" }
    end

    after { subject.shutdown }

    it "notifies observers with the exception" do
      subject.add_observer(observer)
      subject.execute

      _time, result, exception = wait_for_notification
      expect(result).to be_nil
      expect(exception).to be_a(RuntimeError)
      expect(exception.message).to eq("boom")
    end
  end

  context "when the task exceeds the timeout" do
    let(:release) { Concurrent::CountDownLatch.new }

    subject do
      latch = release
      described_class.new(:execution_interval => 0.1, :timeout_interval => 0.1) { latch.wait }
    end

    after { release.count_down; subject.shutdown }

    it "notifies observers with a Concurrent::TimeoutError" do
      subject.add_observer(observer)
      subject.execute

      _time, result, exception = wait_for_notification
      expect(result).to be_nil
      expect(exception).to be_a(Concurrent::TimeoutError)
    end

    it "does not start a second run while one is still in flight" do
      runs = Concurrent::AtomicFixnum.new(0)
      latch = release
      task = described_class.new(:execution_interval => 0.1, :timeout_interval => 0.1) do
        runs.increment
        latch.wait
      end
      task.execute
      sleep(0.6)
      task.shutdown
      release.count_down
      expect(runs.value).to eq(1)
    end
  end

  describe "#shutdown" do
    subject do
      described_class.new(:execution_interval => 0.1, :timeout_interval => 5) { :done }
    end

    it "returns true the first time and false afterwards" do
      subject.execute
      expect(subject.shutdown).to be(true)
      expect(subject.shutdown).to be(false)
    end
  end
end
