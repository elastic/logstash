# encoding: utf-8
require "logstash/queue_factory"
require "logstash/settings"
require "stud/temporary"

describe LogStash::QueueFactory do
  let(:pipeline_id) { "my_pipeline" }
  let(:settings_array) do
    [
      LogStash::Setting::WritableDirectory.new("path.queue", Stud::Temporary.pathname),
      LogStash::Setting::String.new("queue.type", "memory", true, ["persisted", "memory", "memory_acked"]),
      LogStash::Setting::Bytes.new("queue.page_capacity", "250mb"),
      LogStash::Setting::Bytes.new("queue.max_bytes", "1024mb"),
      LogStash::Setting::Numeric.new("queue.max_events", 0),
      LogStash::Setting::Numeric.new("queue.checkpoint.acks", 1024),
      LogStash::Setting::Numeric.new("queue.checkpoint.writes", 1024),
      LogStash::Setting::Numeric.new("queue.checkpoint.interval", 1000),
      LogStash::Setting::String.new("pipeline.id", pipeline_id)
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
      queue =  subject.create(settings)
      expect(queue).to be_kind_of(LogStash::Util::WrappedAckedQueue)
      queue.close
    end

    describe "per pipeline id subdirectory creation" do
      let(:queue_path) { ::File.join(settings.get("path.queue"), pipeline_id) }

      after :each do
        FileUtils.rmdir(queue_path)
      end

      it "creates a queue directory based on the pipeline id" do
        expect(Dir.exist?(queue_path)).to be_falsey
        queue = subject.create(settings)
        expect(Dir.exist?(queue_path)).to be_truthy
        queue.close
      end
    end
  end

  context "when `queue.type` is `memory_acked`" do
    before do
      settings.set("queue.type", "memory_acked")
    end

    it "returns a `WrappedAckedQueue`" do
      queue =  subject.create(settings)
      expect(queue).to be_kind_of(LogStash::Util::WrappedAckedQueue)
      queue.close
    end
  end

  context "when `queue.type` is `memory`" do
    before do
      settings.set("queue.type", "memory")
    end

    it "returns a `WrappedAckedQueue`" do
      queue =  subject.create(settings)
      expect(queue).to be_kind_of(LogStash::Util::WrappedSynchronousQueue)
      queue.close
    end
  end
end
