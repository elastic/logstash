# encoding: utf-8
require "spec_helper"
require "logstash/runner"
require "stud/task"

describe LogStash::AgentPluginManager do
  class TestAgent < LogStash::Agent; end
  class TestAgent2 < LogStash::Agent; end

  subject { described_class }

  after(:each) do
    LogStash::AgentPluginManager.reset!
  end

  describe "the default registry with no registered plugins" do
    it "should have the default agent" do
      expect(subject.lookup(LogStash::AgentPluginManager::DEFAULT_AGENT_NAME)).to eql(LogStash::Agent)
    end

    it "should only have one plugin registered" do
      expect(subject.available.size).to eql(1)
    end

    it "should be able to register an additional plugin" do
      subject.register(:foo, TestAgent)
      expect(subject.lookup(:foo)).to eql(TestAgent)
    end

    it "should not allow two plugins to be registered under the same name" do
      subject.register(:foo, TestAgent)
      expect { subject.register(:foo, TestAgent2) }.to raise_error(LogStash::AgentPluginManager::DuplicatePluginNameError)
    end
  end

end
