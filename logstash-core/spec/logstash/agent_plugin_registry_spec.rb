# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"

describe LogStash::AgentPluginRegistry do
  class TestAgent < LogStash::Agent; end
  class TestAgent2 < LogStash::Agent; end

  subject { described_class }

  after(:each) do
    LogStash::AgentPluginRegistry.reset!
  end

  describe "the default registry with no registered plugins" do
    it "should have the default agent" do
      expect(subject.lookup(LogStash::AgentPluginRegistry::DEFAULT_AGENT_NAME)).to eql(LogStash::Agent)
    end

    it "should only have one plugin registered" do
      expect(subject.available.size).to eql(1)
    end

    it "should be able to register an additional plugin" do
      subject.register(:foo, TestAgent)
      expect(subject.lookup(:foo)).to eql(TestAgent)
    end

    context "with two plugins under the same name" do
      before do
        subject.register(:foo, TestAgent)
      end

      it "should not allow the second plugin to be registered" do
        expect do
          subject.register(:foo, TestAgent2)
        end.to raise_error(LogStash::AgentPluginRegistry::DuplicatePluginError)
      end
    end
  end

end
