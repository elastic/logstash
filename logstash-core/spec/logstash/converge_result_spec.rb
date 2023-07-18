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

require "logstash/pipeline_action/stop"
require "spec_helper"

describe LogStash::ConvergeResult do
  let(:expected_actions_count) { 2 }
  let(:action) { LogStash::PipelineAction::Stop.new(:main) }

  subject { described_class.new(expected_actions_count) }

  context "When the action was executed" do
    it "returns the time of execution" do
      expect(LogStash::ConvergeResult::FailedAction.new("testing").executed_at.class).to eq(LogStash::Timestamp)
      expect(LogStash::ConvergeResult::SuccessfulAction.new.executed_at.class).to eq(LogStash::Timestamp)
    end
  end

  context "conversion of action result" do
    let(:action) { LogStash::PipelineAction::Stop.new(:an_action) }

    context "booleans" do
      context "True" do
        it "converts to a `SuccessfulAction`" do
          subject.add(action, true)
          expect(subject.successful_actions.keys).to include(action)
        end
      end

      context "False" do
        it "converts to a `FailedAction`" do
          subject.add(action, false)
          expect(subject.failed_actions.keys).to include(action)
          expect(subject.failed_actions.values.pop.message).to match(/Could not execute action: #{action}/)
        end
      end
    end

    context "`ActionResult` classes" do
      context "SuccessfulAction" do
        let(:result) { LogStash::ConvergeResult::SuccessfulAction.new }

        it "doesn't convert the class" do
          subject.add(action, result)
          expect(subject.successful_actions.keys).to include(action)
          expect(subject.successful_actions.values).to include(result)
        end
      end

      context "FailedAction" do
        let(:result) { LogStash::ConvergeResult::FailedAction.new("could be worse") }

        it "doesn't convert the class" do
          subject.add(action, result)
          expect(subject.failed_actions.keys).to include(action)
          expect(subject.failed_actions.values).to include(result)
        end
      end
    end

    context "Exception" do
      it "converts to a `FailedAction" do
        begin
          raise ArgumentError, "hello world"
        rescue => e
          subject.add(action, e)

          expect(subject.failed_actions.keys).to include(action)
          failed_action = subject.failed_actions.values.pop

          expect(failed_action.message).to eq("hello world")
          expect(failed_action.backtrace).not_to be_nil
        end
      end
    end
  end

  context "when not all the actions are executed" do
    context "#complete?" do
      it "returns false" do
        expect(subject.complete?).to be_falsey
      end
    end

    context "#success?" do
      it "returns false" do
        expect(subject.success?).to be_falsey
      end
    end
  end

  context "when all the actions are executed" do
    context "all successful" do
      let(:success_action) { LogStash::PipelineAction::Stop.new(:success) }
      let(:success_action_2) { LogStash::PipelineAction::Stop.new(:success_2) }

      before do
        subject.add(success_action, true)
        subject.add(success_action_2, true)
      end

      context "#success?" do
        it "returns true" do
          expect(subject.success?).to be_truthy
        end
      end

      context "#complete?" do
        it "returns true" do
          expect(subject.complete?).to be_truthy
        end
      end

      context "filtering on the actions result" do
        it "returns the successful actions" do
          expect(subject.successful_actions.size).to eq(2)
          expect(subject.successful_actions.keys).to include(success_action, success_action_2)
        end

        it "returns the failed actions" do
          expect(subject.failed_actions.size).to eq(0)
        end
      end
    end

    context "not successfully" do
      let(:success_action) { LogStash::PipelineAction::Stop.new(:success) }
      let(:failed_action) { LogStash::PipelineAction::Stop.new(:failed) }

      before do
        subject.add(failed_action, false)
        subject.add(success_action, true)
      end

      context "#success?" do
        it "returns false" do
          expect(subject.success?).to be_falsey
        end
      end

      context "#complete?" do
        it "returns true" do
          expect(subject.complete?).to be_truthy
        end
      end

      context "#total" do
        it "returns the number of actions" do
          expect(subject.total).to eq(2)
        end
      end

      context "#fails_count" do
        it "returns the number of actions" do
          expect(subject.fails_count).to eq(1)
        end
      end

      context "#success_count" do
        it "returns the number of actions" do
          expect(subject.success_count).to eq(1)
        end
      end

      context "filtering on the actions result" do
        it "returns the successful actions" do
          expect(subject.successful_actions.size).to eq(1)
          expect(subject.successful_actions.keys).to include(success_action)
        end

        it "returns the failed actions" do
          expect(subject.failed_actions.size).to eq(1)
          expect(subject.failed_actions.keys).to include(failed_action)
        end
      end
    end
  end
end
