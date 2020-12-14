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
require_relative "../support/helpers"
require_relative "../support/mocks_classes"

#TODO: Figure out how to add more tests that actually cover inflight events
#This will require some janky multithreading stuff
shared_examples "a pipeline reporter" do |pipeline_setup|
  let(:generator_count) { 5 }
  let(:config) do
    "input { generator { count => #{generator_count} } } output { dummyoutput {} } "
  end
  let(:pipeline) { Kernel.send(pipeline_setup, config)}
  let(:reporter) { pipeline.reporter }

  before do
    allow(LogStash::Plugin).to receive(:lookup).with("output", "dummyoutput").and_return(::LogStash::Outputs::DummyOutput)
    allow(LogStash::Plugin).to receive(:lookup).with("input", "generator").and_call_original
    allow(LogStash::Plugin).to receive(:lookup).with("codec", "plain").and_call_original

    @pre_snapshot = reporter.snapshot

    pipeline.start
    # wait for stopped? so the input can produce all events
    sleep 0.01 until pipeline.stopped?
    pipeline.shutdown
    @post_snapshot = reporter.snapshot
  end

  describe "stalling threads info" do
    it "should start with no stalled threads" do
      expect(@pre_snapshot.stalling_threads_info).to eql([])
    end

    it "should end with no stalled threads" do
      expect(@pre_snapshot.stalling_threads_info).to eql([])
    end
  end

  describe "events filtered" do
    it "should start at zero" do
      expect(@pre_snapshot.events_filtered).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_filtered).to eql(generator_count)
    end
  end

  describe "events consumed" do
    it "should start at zero" do
      expect(@pre_snapshot.events_consumed).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_consumed).to eql(generator_count)
    end
  end

  describe "inflight count" do
    it "should be zero before running" do
      expect(@pre_snapshot.inflight_count).to eql(0)
    end

    it "should be zero after running" do
      expect(@post_snapshot.inflight_count).to eql(0)
    end
  end
end

describe LogStash::PipelineReporter do
  context "with java execution" do
    it_behaves_like "a pipeline reporter", :mock_java_pipeline_from_string
  end
end
