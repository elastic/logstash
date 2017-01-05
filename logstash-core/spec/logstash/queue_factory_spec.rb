# encoding: utf-8
require "logstash/queue_factory"
require "logstash/settings"
require "stud/temporary"

describe LogStash::QueueFactory do
  let(:settings_array) do
    [
      LogStash::Setting::WritableDirectory.new("path.queue", Stud::Temporary.pathname),
      LogStash::Setting::String.new("queue.type", "memory", true, ["persisted", "memory", "memory_acked"]),
      LogStash::Setting::Bytes.new("queue.page_capacity", "250mb"),
      LogStash::Setting::Bytes.new("queue.max_bytes", "1024mb"),
      LogStash::Setting::Numeric.new("queue.max_events", 0),
      LogStash::Setting::Numeric.new("queue.checkpoint.acks", 1024),
      LogStash::Setting::Numeric.new("queue.checkpoint.writes", 1024),
      LogStash::Setting::Numeric.new("queue.checkpoint.interval", 1000)
    ]
  end

  let(:settings) do
    s = LogStash::Settings.new

    settings_array.each do |setting|
      s.register(setting)
    end
    s
  end

  subject { described_class }

  context "when `queue.type` is `persisted`" do
    before do
      settings.set("queue.type", "persisted")
    end

    it "returns a `WrappedAckedQueue`" do
      expect(subject.create(settings)).to be_kind_of(LogStash::Util::WrappedAckedQueue)
    end
  end

  context "when `queue.type` is `memory_acked`" do
    before do
      settings.set("queue.type", "memory_acked")
    end

    it "returns a `WrappedAckedQueue`" do
      expect(subject.create(settings)).to be_kind_of(LogStash::Util::WrappedAckedQueue)
    end
  end

  context "when `queue.type` is `memory`" do
    before do
      settings.set("queue.type", "memory")
    end

    it "returns a `WrappedAckedQueue`" do
      expect(subject.create(settings)).to be_kind_of(LogStash::Util::WrappedSynchronousQueue)
    end
  end
end
