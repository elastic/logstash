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

describe LogStash::ShutdownWatcher do
  let(:check_every) { 0.01 }
  let(:check_threshold) { 100 }
  subject { LogStash::ShutdownWatcher.new(pipeline, check_every) }
  let(:pipeline) { double("pipeline") }
  let(:reporter) { double("reporter") }
  let(:reporter_snapshot) { double("reporter snapshot") }

  before :each do
    allow(pipeline).to receive(:reporter).and_return(reporter)
    allow(pipeline).to receive(:thread).and_return(Thread.current)
    allow(reporter).to receive(:snapshot).and_return(reporter_snapshot)
    allow(reporter_snapshot).to receive(:o_simple_hash).and_return({})
  end

  context "when pipeline is stalled" do
    let(:increasing_count) { (1..5000).to_a }
    before :each do
      allow(reporter_snapshot).to receive(:inflight_count).and_return(*increasing_count)
      allow(reporter_snapshot).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        expect(thread.join(60)).to_not be_nil
      end
    end
  end

  context "when pipeline is not stalled" do
    let(:decreasing_count) { (1..5000).to_a.reverse }
    before :each do
      allow(reporter_snapshot).to receive(:inflight_count).and_return(*decreasing_count)
      allow(reporter_snapshot).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = true" do

      before :each do
        subject.class.unsafe_shutdown = true
      end

      it "should force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        expect(thread.join(60)).to_not be_nil
      end
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        thread.join
        expect(thread.join(60)).to_not be_nil
      end
    end
  end
end
