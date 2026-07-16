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

require "logstash/settings"
require "stud/temporary"

describe LogStash::QueueFactory do
  let(:pipeline_id) { "my_pipeline" }
  let(:settings_array) do
    [
      LogStash::Setting::WritableDirectorySetting.new("path.queue", Stud::Temporary.pathname),
      LogStash::Setting::StringSetting.new("queue.type", "memory", true, ["persisted", "memory"]),
      LogStash::Setting::BytesSetting.new("queue.page_capacity", "8mb"),
      LogStash::Setting::BytesSetting.new("queue.max_bytes", "64mb"),
      LogStash::Setting::NumericSetting.new("queue.max_events", 0),
      LogStash::Setting::NumericSetting.new("queue.checkpoint.acks", 1024),
      LogStash::Setting::NumericSetting.new("queue.checkpoint.writes", 1024),
      LogStash::Setting::BooleanSetting.new("queue.checkpoint.retry", false),
      LogStash::Setting::StringSetting.new("queue.compression", "none", true, %w(none speed balanced size disabled)),
      LogStash::Setting::StringSetting.new("pipeline.id", pipeline_id),
      LogStash::Setting::StringSetting.new("pipeline.batch.metrics.sampling_mode", "minimal", true, ["disabled", "minimal", "full"]),
      LogStash::Setting::PositiveIntegerSetting.new("pipeline.batch.size", 125),
      LogStash::Setting::PositiveIntegerSetting.new("pipeline.workers", LogStash::Config::CpuCoreStrategy.maximum)
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
    let(:queue_path) { ::File.join(settings.get("path.queue"), pipeline_id) }

    before do
      settings.set("queue.type", "persisted")
    end

    after(:each) do
      FileUtils.rm_rf(queue_path)
    end

    it "returns a `WrappedAckedQueue`" do
      queue = subject.create(settings)
      expect(queue).to be_kind_of(LogStash::WrappedAckedQueue)
      queue.close
    end

    describe "per pipeline id subdirectory creation" do

      it "creates a queue directory based on the pipeline id" do
        expect(Dir.exist?(queue_path)).to be_falsey
        queue = subject.create(settings)
        expect(Dir.exist?(queue_path)).to be_truthy
        queue.close
      end
    end

    context "when queue.max_bytes is larger than Java int" do
      let(:large_queue_max_bytes) { 2**31 } # 2^31 bytes, bigger than 2^31-1 int limit
      before(:each) do
        settings.set("queue.max_bytes", large_queue_max_bytes)
      end
      it "does not raise error" do
        queue = nil
        expect { queue = subject.create(settings) }.to_not raise_error
        expect(queue.queue.max_size_in_bytes).to eq(large_queue_max_bytes)
        queue.close
      end
    end
  end

  context "when `queue.type` is `memory`" do
    before do
      settings.set("queue.type", "memory")
      settings.set("pipeline.batch.size", 1024)
    end

    it "returns a `WrappedSynchronousQueue`" do
      queue = subject.create(settings)
      expect(queue).to be_kind_of(LogStash::WrappedSynchronousQueue)
      queue.close
    end
  end
end
