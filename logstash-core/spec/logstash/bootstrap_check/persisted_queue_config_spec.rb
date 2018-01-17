require "spec_helper"
require "tmpdir"
require "logstash/bootstrap_check/persisted_queue_config"

describe LogStash::BootstrapCheck::PersistedQueueConfig do

  context("when persisted queues are enabled") do
    let(:settings) do
      settings = LogStash::SETTINGS.dup
      settings.set_value("queue.type", "persisted")
      settings.set_value("queue.page_capacity", 1024)
      settings.set_value("path.queue", ::File.join(Dir.tmpdir, "some/path"))
      settings
    end

    context("and 'queue.max_bytes' is set to a value less than the value of 'queue.page_capacity'") do
      it "should throw" do
        settings.set_value("queue.max_bytes", 512)
        expect { LogStash::BootstrapCheck::PersistedQueueConfig.check(settings) }.to raise_error
      end
    end
  end
end