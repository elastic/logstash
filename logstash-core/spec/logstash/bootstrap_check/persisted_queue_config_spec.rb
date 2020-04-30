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