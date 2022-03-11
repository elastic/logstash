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

require "spec_helper"
require "tmpdir"
require "logstash/bootstrap_check/persisted_queue_config"
require_relative '../../support/helpers'

describe LogStash::BootstrapCheck::PersistedQueueConfig do

  context("when persisted queues are enabled") do
    let(:input_block) { "input { generator {} }" }
    let(:config_path) { temporary_file(input_block) }
    let(:queue_path) { Stud::Temporary.directory }
    let(:settings) do
      mock_settings(
        "queue.type" => "persisted",
        "queue.page_capacity" => 1024,
        "path.queue" => queue_path,
        "path.config" => config_path
      )
    end
    let(:pipeline_configs) { LogStash::Config::Source::Local.new(settings).pipeline_configs }

    context("'queue.max_bytes' is less than 'queue.page_capacity'") do
      it "should throw" do
        settings.set_value("queue.max_bytes", 512)
        expect { LogStash::BootstrapCheck::PersistedQueueConfig.check({}, pipeline_configs) }
          .to raise_error(LogStash::BootstrapCheckError, /'queue.page_capacity' must be less than or equal to 'queue.max_bytes'/)
      end
    end

    context("'queue.max_bytes' = 0 which is less than 'queue.page_capacity'") do
      it "should not throw" do
        settings.set_value("queue.max_bytes", 0)
        expect { LogStash::BootstrapCheck::PersistedQueueConfig.check({}, pipeline_configs) }
          .not_to raise_error
      end
    end

    context("queue size is greater than 'queue.max_bytes'") do
      let(:pipeline_id) { "main" }
      let(:page_file) do
        FileUtils.mkdir_p(::File.join(queue_path, pipeline_id))
        ::File.new(::File.join(queue_path, pipeline_id, "page.0"), "w")
      end

      before do
        # create a 2MB file
        page_file.truncate(2 ** 21)
      end

      it "should throw" do
        settings.set_value("queue.max_bytes", "1mb")
        expect { LogStash::BootstrapCheck::PersistedQueueConfig.check({}, pipeline_configs) }
          .to raise_error(LogStash::BootstrapCheckError, /greater than 'queue.max_bytes'/)
      end

      after do
        page_file.truncate(0)
        page_file.close
      end
    end

    context("disk does not have sufficient space") do
      # two pq with different paths
      let(:settings1) { settings.dup.merge("queue.max_bytes" => "1000pb") }
      let(:settings2) { settings1.dup.merge("path.queue" => Stud::Temporary.directory) }

      let(:pipeline_configs) do
        LogStash::Config::Source::Local.new(settings1).pipeline_configs +
          LogStash::Config::Source::Local.new(settings2).pipeline_configs
      end

      it "should throw" do
        expect(LogStash::BootstrapCheck::PersistedQueueConfig).to receive(:check_disk_space) do | _, _, required_free_bytes|
          expect(required_free_bytes.size).to eq(1)
          expect(required_free_bytes.values[0]).to eq(1024**5 * 1000 * 2) # require 2000pb
        end.and_call_original

        expect { LogStash::BootstrapCheck::PersistedQueueConfig.check({}, pipeline_configs) }
          .to raise_error(LogStash::BootstrapCheckError, /is unable to allocate/)
      end
    end

    context("queue config check update") do
      shared_examples "no update" do
        it "gives false" do
          expect(LogStash::BootstrapCheck::PersistedQueueConfig.queue_configs_updated?(running_pipelines, pipeline_configs))
            .to be_falsey
        end
      end

      shared_examples "got update" do
        it "gives true" do
          expect(LogStash::BootstrapCheck::PersistedQueueConfig.queue_configs_updated?(running_pipelines, pipeline_configs))
            .to be_truthy
        end
      end

      let(:java_pipeline) { LogStash::JavaPipeline.new(pipeline_configs[0]) }
      let(:running_pipelines) { {:main => java_pipeline } }

      context("pipeline config is identical") do
        it_behaves_like "no update"
      end

      context("add more pipeline") do
        let(:settings1) { settings.dup.merge("pipeline.id" => "main") }
        let(:settings2) { settings.dup.merge("pipeline.id" => "second") }
        let(:pipeline_configs) do
          LogStash::Config::Source::Local.new(settings1).pipeline_configs +
            LogStash::Config::Source::Local.new(settings2).pipeline_configs
        end

        it_behaves_like "got update"
      end

      context("queue configs has changed") do
        let(:settings1) { settings.dup.merge("queue.max_bytes" => "1mb") }
        let(:pipeline_configs1) { LogStash::Config::Source::Local.new(settings1).pipeline_configs }
        let(:java_pipeline) { LogStash::JavaPipeline.new(pipeline_configs1[0]) }

        it_behaves_like "got update"
      end

      context("queue configs do not changed") do
        let(:settings1) { settings.dup.merge("config.debug" => "true") }
        let(:pipeline_configs) { LogStash::Config::Source::Local.new(settings1).pipeline_configs }

        it_behaves_like "no update"
      end
    end
  end
end