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
require "logstash/pipelines_registry"

describe LogStash::PipelinesRegistry do

  let(:pipeline_id) { "test" }
  let(:pipeline) { double("Pipeline") }
  let (:logger) { double("Logger") }

  context "at object creation" do
    it "should be empty" do
      expect(subject.size).to eq(0)
      expect(subject.empty?).to be_truthy
      expect(subject.running_pipelines).to be_empty
      expect(subject.non_running_pipelines).to be_empty
      expect(subject.running_user_defined_pipelines).to be_empty
    end
  end

  context "creating a pipeline" do
    context "without existing same pipeline id" do
      it "registry should not have a state for pipeline_id" do
        expect(subject.get_pipeline(pipeline_id)).to be_nil
      end

      it "should return block return value" do
        expect(subject.create_pipeline(pipeline_id, pipeline) { "dummy" }).to eq("dummy")
      end

      it "should register the new pipeline upon successful create block" do
        subject.create_pipeline(pipeline_id, pipeline) { true }
        expect(subject.get_pipeline(pipeline_id)).to eq(pipeline)
      end

      it "should not register the new pipeline upon unsuccessful create block" do
        subject.create_pipeline(pipeline_id, pipeline) { false }
        expect(subject.get_pipeline(pipeline_id)).to be_nil
      end
    end

    context "with existing pipeline id" do
      before :each do
        subject.create_pipeline(pipeline_id, pipeline) { true }
      end

      it "registry should have a state for pipeline_id" do
        expect(subject.get_pipeline(pipeline_id)).to eq(pipeline)
      end

      context "when existing pipeline is not terminated" do
        before :each do
          expect(pipeline).to receive(:finished_execution?).and_return(false)
        end

        it "should return false" do
          expect(subject.create_pipeline(pipeline_id, pipeline) { "dummy" }).to be_falsey
        end

        it "should not call block and log error if pipeline is not terminated" do
          expect(LogStash::PipelinesRegistry).to receive(:logger).and_return(logger)
          expect(logger).to receive(:error)
          expect { |b| subject.create_pipeline(pipeline_id, pipeline, &b) }.not_to yield_control
        end
      end

      context "when existing pipeline is terminated" do
        let (:new_pipeline) { double("New Pipeline") }

        before :each do
          expect(pipeline).to receive(:finished_execution?).and_return(true)
        end

        it "should return block value" do
          expect(subject.create_pipeline(pipeline_id, new_pipeline) { "dummy" }).to eq("dummy")
        end

        it "should return block value" do
          expect(subject.create_pipeline(pipeline_id, new_pipeline) { "dummy" }).to eq("dummy")
        end

        it "should register new pipeline" do
          subject.create_pipeline(pipeline_id, new_pipeline) { true }
          expect(subject.get_pipeline(pipeline_id)).to eq(new_pipeline)
        end
      end
    end
  end

  context "terminating a pipeline" do
    context "without existing pipeline id" do
      it "should log error" do
        expect(LogStash::PipelinesRegistry).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error)
        subject.terminate_pipeline(pipeline_id) { "dummy" }
      end

      it "should not yield to block" do
        expect { |b| subject.terminate_pipeline(pipeline_id, &b) }.not_to yield_control
      end
    end

    context "with existing pipeline id" do
      before :each do
        subject.create_pipeline(pipeline_id, pipeline) { true }
      end

      it "should yield to block" do
        expect { |b| subject.terminate_pipeline(pipeline_id, &b) }.to yield_control
      end

      it "should keep pipeline id" do
        subject.terminate_pipeline(pipeline_id) { "dummy" }
        expect(subject.get_pipeline(pipeline_id)).to eq(pipeline)
      end
    end
  end

  context "reloading a pipeline" do
    it "should log error with inexistent pipeline id" do
      expect(LogStash::PipelinesRegistry).to receive(:logger).and_return(logger)
      expect(logger).to receive(:error)
      subject.reload_pipeline(pipeline_id) { }
    end

    context "with existing pipeline id" do
      before :each do
        subject.create_pipeline(pipeline_id, pipeline) { true }
      end

      it "should return block value" do
        expect(subject.reload_pipeline(pipeline_id) { ["dummy", pipeline] }).to eq("dummy")
      end

      it "should not be terminated while reloading" do
        expect(pipeline).to receive(:finished_execution?).and_return(false, true, true)

        # 1st call: finished_execution? is false
        expect(subject.running_pipelines).not_to be_empty

        # 2nd call: finished_execution? is true
        expect(subject.running_pipelines).to be_empty


        queue = Queue.new # threadsafe queue
        in_block = Concurrent::AtomicBoolean.new(false)

        thread = Thread.new(subject, pipeline_id, pipeline, queue, in_block) do |subject, pipeline_id, pipeline, queue, in_block|
          subject.reload_pipeline(pipeline_id) do
            in_block.make_true
            queue.pop
            [true, pipeline]
          end
        end

        # make sure we entered the block executioin
        wait(10).for {in_block.true?}.to be_truthy

        # at this point the thread is suspended waiting on queue

        # since in reloading state, running_pipelines is not empty
        expect(subject.running_pipelines).not_to be_empty

        # unblock thread
        queue.push(:dummy)
        thread.join

        # 3rd call: finished_execution? is true
        expect(subject.running_pipelines).to be_empty
      end
    end
  end

  context "pipelines collections" do
    context "with a non terminated pipelines" do
      before :each do
        subject.create_pipeline(pipeline_id, pipeline) { true }
        expect(pipeline).to receive(:finished_execution?).and_return(false)
      end

      it "should find running pipelines" do
        expect(subject.running_pipelines).not_to be_empty
      end

      it "should not find non_running pipelines" do
        expect(subject.non_running_pipelines).to be_empty
      end

      it "should find running_user_defined_pipelines" do
        expect(pipeline).to receive(:system?).and_return(false)
        expect(subject.running_user_defined_pipelines).not_to be_empty
      end

      it "should not find running_user_defined_pipelines" do
        expect(pipeline).to receive(:system?).and_return(true)
        expect(subject.running_user_defined_pipelines).to be_empty
      end
    end

    context "with a terminated pipelines" do
      before :each do
        subject.create_pipeline(pipeline_id, pipeline) { true }
        expect(pipeline).to receive(:finished_execution?).and_return(true)
      end

      it "should not find running pipelines" do
        expect(subject.running_pipelines).to be_empty
      end

      it "should find non_running pipelines" do
        expect(subject.non_running_pipelines).not_to be_empty
      end

      it "should not find running_user_defined_pipelines" do
        expect(subject.running_user_defined_pipelines).to be_empty
      end
    end

  end
end
