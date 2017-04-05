# encoding: utf-8
require "spec_helper"
require "tmpdir"

class DLQCommittingInput < LogStash::Inputs::Base
  config_name "dlq_commit"
  milestone 2

  def register
  end

  def run(queue)
    (0..9).each do |i|
      event = LogStash::Event.new({"i" => i})
      @codec.decode(event) do |event|
        dlq_commit(event, "testing input")
        queue << event
      end
    end
  end

  def close
  end
end

class DLQCommittingCodec < LogStash::Codecs::Base
  config_name "dlq_commit"
  milestone 2

  def decode(data)
    dlq_commit(data, "testing codec#decode")
    yield data
  end

  def encode(event)
    dlq_commit(event, "testing codec#encode")
    @on_event.call(event, "foobar")
  end

  def close
  end
end

class DLQCommittingFilter < LogStash::Filters::Base
  config_name "dlq_commit"
  milestone 2

  def register() end

  def filter(event)
    dlq_commit(event, "testing filter")
  end

  def threadsafe?() true; end

  def close() end
end

class DLQCommittingOutput < LogStash::Outputs::Base
  config_name "dlq_commit"
  milestone 2

  def register
    @codec.on_event do |event, data|
      dlq_commit(event, "testing output")
    end
  end

  def receive(event)
    @codec.encode(event)
  end

  def threadsafe?() true; end

  def close() end
end

describe LogStash::Pipeline do
  let(:pipeline_settings_obj) { LogStash::SETTINGS }
  let(:pipeline_id) { "test" }
  let(:pipeline_settings) do
    {
      "pipeline.workers" => 2,
      "pipeline.id" => pipeline_id,
      "dead_letter_queue.enable" => true,
      "path.dead_letter_queue" => Dir.mktmpdir
    }
  end
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }
  let(:test_config) {
    <<-eos
        input {
          dlq_commit { codec => dlq_commit }
        }

        filter {
          dlq_commit {}
        }

        output {
          dlq_commit { codec => dlq_commit }
        }
    eos
  }

  subject { LogStash::Pipeline.new(test_config, pipeline_settings_obj, metric) }

  before(:each) do
    pipeline_settings.each {|k, v| pipeline_settings_obj.set(k, v) }
    allow(LogStash::Plugin).to receive(:lookup).with("input", "dlq_commit").and_return(DLQCommittingInput)
    allow(LogStash::Plugin).to receive(:lookup).with("codec", "dlq_commit").and_return(DLQCommittingCodec)
    allow(LogStash::Plugin).to receive(:lookup).with("filter", "dlq_commit").and_return(DLQCommittingFilter)
    allow(LogStash::Plugin).to receive(:lookup).with("output", "dlq_commit").and_return(DLQCommittingOutput)
  end

  after(:each) do
    FileUtils.remove_entry pipeline_settings["path.dead_letter_queue"]
  end


  it "executes dlq_commit from inputs/filters/outputs only. no codecs" do
    subject.run
    subject.close
    dlq_path = java.nio.file.Paths.get(pipeline_settings_obj.get("path.dead_letter_queue"), pipeline_id)
    dlq_reader = org.logstash.common.io.DeadLetterQueueReadManager.new(dlq_path)
    commit_count = 0
    (0..30).each do |i|
      entry = dlq_reader.pollEntry(40)
      if i < 30
        commit_count += 1
      else
        expect(i).to eq(30)
        expect(entry).to be_nil
      end
    end
    expect(commit_count).to eq(30)
  end
end
