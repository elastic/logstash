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

require "logstash/agent"
require_relative "../../support/helpers"
require_relative "../../support/matchers"
require_relative "../../support/mocks_classes"
require "spec_helper"

describe LogStash::Agent do
  # by default no tests uses the auto reload logic
  let(:agent_settings) { mock_settings("config.reload.automatic" => false, "queue.type" => "persisted") }

  subject { described_class.new(agent_settings, source_loader) }

  before do
    clear_data_dir

    # until we decouple the webserver from the agent
    allow(subject).to receive(:start_webserver).and_return(false)
    allow(subject).to receive(:stop_webserver).and_return(false)
  end

  # Make sure that we close any running pipeline to release any pending locks
  # on the queues
  after do
    converge_result = subject.shutdown
    expect(converge_result).to be_a_successful_converge
  end

  context "Agent execute options" do
    let(:source_loader) do
      TestSourceLoader.new(finite_pipeline_config)
    end

    context "when the pipeline execution is finite" do
      let(:finite_pipeline_config) { mock_pipeline_config(:main, "input { generator { count => 1000 } } output { null {} }") }

      it "execute the pipeline and stop execution" do
        expect(subject.execute).to eq(0)
      end
    end

    context "when the config is short lived (generator { count => 1 })" do
      let(:finite_pipeline_config) { mock_pipeline_config(:main, "input { generator { count => 1 } } output { null {} }") }

      it "execute the pipeline and stop execution" do
        expect(subject.execute).to eq(0)
      end
    end

    context "system pipeline" do
      let(:system_pipeline_config) { mock_pipeline_config(:system_pipeline, "input { dummyblockinginput { } } output { null {} }", { "pipeline.system" => true }) }

      context "when we have a finite pipeline and a system pipeline running" do
        let(:finite_pipeline_config) { mock_pipeline_config(:main, "input { generator { count => 1000 } } output { null {} }") }

        let(:source_loader) do
          TestSourceLoader.new(finite_pipeline_config, system_pipeline_config)
        end

        it "execute the pipeline and stop execution" do
          expect(subject.execute).to eq(0)
        end
      end

      context "when we have an infinite pipeline and a system pipeline running" do
        let(:infinite_pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { } } output { null {} }") }

        let(:source_loader) do
          TestSourceLoader.new(infinite_pipeline_config, system_pipeline_config)
        end

        before(:each) do
          @agent_task = start_agent(subject)
        end

        after(:each) do
          @agent_task.stop!
          @agent_task.wait
          subject.shutdown
        end

        describe "#running_user_defined_pipelines" do
          it "returns the user defined pipelines" do
            # wait is necessary to accommodate for pipelines startup time
            wait(60).for {subject.running_user_defined_pipelines.keys}.to eq([:main])
           end
        end

        describe "#running_user_defined_pipelines?" do
          it "returns true" do
            # wait is necessary to accommodate for pipelines startup time
            wait(60).for {subject.running_user_defined_pipelines?}.to be_truthy
          end
        end
      end
    end

    context "when `config.reload.automatic`" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput {} } output { null {} }") }

      let(:source_loader) do
        TestSourceLoader.new(pipeline_config)
      end

      context "is set to`FALSE`" do
        context "and successfully load the config" do
          let(:agent_settings) { mock_settings("config.reload.automatic" => false) }

          before(:each) do
            @agent_task = start_agent(subject)
          end

          after(:each) do
            @agent_task.stop!
            @agent_task.wait
            subject.shutdown
          end

          it "converge only once" do
            wait(60).for { source_loader.fetch_count }.to eq(1)
            # no need to wait here because have_running_pipeline? does the wait
            expect(subject).to have_running_pipeline?(pipeline_config)
          end
        end

        context "and it fails to load the config" do
          let(:source_loader) do
            TestSourceLoader.new(TestSourceLoader::FailedFetch.new("can't load the file"))
          end

          it "doesn't execute any pipeline" do
            expect { subject.execute }.not_to raise_error # errors is logged

            expect(source_loader.fetch_count).to eq(1)
            expect(subject.pipelines_count).to eq(0)
          end
        end
      end

      context "is set to `TRUE`" do
        let(:interval) { "10ms" }
        let(:agent_settings) do
          mock_settings(
            "config.reload.automatic" => true,
            "config.reload.interval" =>  interval
          )
        end

        before(:each) do
          @agent_task = start_agent(subject)
        end

        after(:each) do
          @agent_task.stop!
          @agent_task.wait
          subject.shutdown
        end

        context "and successfully load the config" do
          it "converges periodically the pipelines from the configs source" do
            # no need to wait here because have_running_pipeline? does the wait
            expect(subject).to have_running_pipeline?(pipeline_config)

            # we rely on a periodic thread to call fetch count, we have seen unreliable run on
            # travis, so lets add a few retries
            try { expect(source_loader.fetch_count).to be > 1 }
          end
        end

        context "and it fails to load the config" do
          let(:source_loader) do
            TestSourceLoader.new(TestSourceLoader::FailedFetch.new("can't load the file"))
          end

          it "it will keep trying to converge" do
            # we can't do .to_seconds here as values under 1 seconds are rounded to 0
            # causing a race condition in the test. So we get the nanos and convert to seconds
            sleep(agent_settings.get("config.reload.interval").to_nanos * 1e-9 * 20) # let the interval reload a few times
            expect(subject.pipelines_count).to eq(0)
            expect(source_loader.fetch_count).to be > 1
          end
        end
      end
    end
  end

  context "when shutting down the agent" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput {} } output { null {} }") }
    let(:new_pipeline_config) { mock_pipeline_config(:new, "input { dummyblockinginput { id => 'new' } } output { null {} }") }

    let(:source_loader) do
      TestSourceLoader.new([pipeline_config, new_pipeline_config])
    end

    it "stops the running pipelines" do
      expect(subject.converge_state_and_update).to be_a_successful_converge
      expect { subject.shutdown }.to change { subject.running_pipelines_count }.from(2).to(0)
    end
  end

  context "Configuration converge scenario" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput {} } output { null {} }", { "pipeline.reloadable" => true }) }
    let(:new_pipeline_config) { mock_pipeline_config(:new, "input { dummyblockinginput {} } output { null {} }", { "pipeline.reloadable" => true }) }

    before do
      # Set the Agent to an initial state of pipelines
      expect(subject.converge_state_and_update).to be_a_successful_converge
    end

    context "no pipelines is running" do
      let(:source_loader) do
        TestSequenceSourceLoader.new([], pipeline_config)
      end

      it "creates and starts the new pipeline" do
        expect {
          expect(subject.converge_state_and_update).to be_a_successful_converge
        }.to change { subject.running_pipelines_count }.from(0).to(1)
        expect(subject).to have_running_pipeline?(pipeline_config)
      end
    end

    context "when a pipeline is running" do
      context "when the source returns the current pipeline and a new one" do
        let(:source_loader) do
          TestSequenceSourceLoader.new(
            pipeline_config,
            [pipeline_config, new_pipeline_config]
          )
        end

        it "start a new pipeline and keep the original" do
          expect {
            expect(subject.converge_state_and_update).to be_a_successful_converge
          }.to change { subject.running_pipelines_count }.from(1).to(2)
          expect(subject).to have_running_pipeline?(pipeline_config)
          expect(subject).to have_running_pipeline?(new_pipeline_config)
        end
      end

      context "when the source returns a new pipeline but not the old one" do
        let(:source_loader) do
          TestSequenceSourceLoader.new(
            pipeline_config,
            new_pipeline_config
          )
        end

        it "stops the missing pipeline and start the new one" do
          expect {
            expect(subject.converge_state_and_update).to be_a_successful_converge
          }.not_to change { subject.running_pipelines_count }
          expect(subject).not_to have_pipeline?(pipeline_config)
          expect(subject).to have_running_pipeline?(new_pipeline_config)
        end
      end
    end

    context "when the source return a modified pipeline" do
      let(:modified_pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { id => 'new-and-modified' } } output { null {} }", { "pipeline.reloadable" => true }) }

      let(:source_loader) do
        TestSequenceSourceLoader.new(
          [pipeline_config],
          [modified_pipeline_config]
        )
      end

      it "reloads the modified pipeline" do
        expect {
          expect(subject.converge_state_and_update).to be_a_successful_converge
        }.not_to change { subject.running_pipelines_count }
        expect(subject).to have_running_pipeline?(modified_pipeline_config)
        expect(subject).to have_stopped_pipeline?(pipeline_config)
      end
    end

    context "when the source return no pipelines" do
      let(:source_loader) do
        TestSequenceSourceLoader.new(
          [pipeline_config, new_pipeline_config],
          []
        )
      end

      it "stops all the pipelines" do
        expect {
          expect(subject.converge_state_and_update).to be_a_successful_converge
        }.to change { subject.running_pipelines_count }.from(2).to(0)
        expect(subject).not_to have_pipeline?(pipeline_config)
      end
    end
  end
end
