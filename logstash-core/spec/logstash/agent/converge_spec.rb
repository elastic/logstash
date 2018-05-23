# encoding: utf-8
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
      
      let(:system_pipeline_config) { mock_pipeline_config(:system_pipeline, "input { generator { } } output { null {} }", { "pipeline.system" => true }) }

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
        let(:infinite_pipeline_config) { mock_pipeline_config(:main, "input { generator { } } output { null {} }") }

        let(:source_loader) do
          TestSourceLoader.new(infinite_pipeline_config, system_pipeline_config)
        end

        before(:each) do
            @agent_task = start_agent(subject)
        end

        after(:each) do
            @agent_task.stop!
        end

        describe "#running_user_defined_pipelines" do
          it "returns the user defined pipelines" do
            wait_for do
              subject.with_running_user_defined_pipelines {|pipelines| pipelines.keys }
            end.to eq([:main])
          end
        end

        describe "#running_user_defined_pipelines?" do
          it "returns true" do
            wait_for do
              subject.running_user_defined_pipelines?
            end.to be_truthy
          end
        end
      end
    end

    context "when `config.reload.automatic`" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { generator {} } output { null {} }") }

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
          end

          it "converge only once" do
            wait(60).for { source_loader.fetch_count }.to eq(1)

            expect(subject).to have_running_pipeline?(pipeline_config)

            subject.shutdown
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

            subject.shutdown
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
        end

        context "and successfully load the config" do
          it "converges periodically the pipelines from the configs source" do
            sleep(2) # let the interval reload a few times
            expect(subject).to have_running_pipeline?(pipeline_config)

            # we rely on a periodic thread to call fetch count, we have seen unreliable run on
            # travis, so lets add a few retries
            try do
              expect(source_loader.fetch_count).to be > 1
            end

            subject.shutdown
          end
        end

        context "and it fails to load the config" do
          let(:source_loader) do
            TestSourceLoader.new(TestSourceLoader::FailedFetch.new("can't load the file"))
          end

          it "it will keep trying to converge" do

            sleep(agent_settings.get("config.reload.interval") / 1_000_000_000.0 * 20) # let the interval reload a few times
            expect(subject.pipelines_count).to eq(0)
            expect(source_loader.fetch_count).to be > 1

            subject.shutdown
          end
        end
      end
    end
  end

  context "when shutting down the agent" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { generator {} } output { null {} }") }
    let(:new_pipeline_config) { mock_pipeline_config(:new, "input { generator { id => 'new' } } output { null {} }") }

    let(:source_loader) do
      TestSourceLoader.new([pipeline_config, new_pipeline_config])
    end

    it "stops the running pipelines" do
      expect(subject.converge_state_and_update).to be_a_successful_converge
      expect { subject.shutdown }.to change { subject.running_pipelines_count }.from(2).to(0)
    end
  end

  context "Configuration converge scenario" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { generator {} } output { null {} }", { "pipeline.reloadable" => true }) }
    let(:new_pipeline_config) { mock_pipeline_config(:new, "input { generator {} } output { null {} }", { "pipeline.reloadable" => true }) }

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
      let(:modified_pipeline_config) { mock_pipeline_config(:main, "input { generator { id => 'new-and-modified' } } output { null {} }", { "pipeline.reloadable" => true }) }

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
        expect(subject).not_to have_pipeline?(pipeline_config)
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
