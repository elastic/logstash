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
require "logstash/pipeline_resource_usage_validator"
require_relative '../support/helpers'

describe LogStash::PipelineResourceUsageValidator do
  let(:max_heap_size) { 1 * 1024 * 1024 * 1024 } # 1 GB
  subject { LogStash::PipelineResourceUsageValidator.new(max_heap_size) }
  let(:logger) { subject.logger }
  let(:pipelines_registry) { double(:pipelines_registry) }
  let(:pipeline_count) { 10 }

  before(:each) do
    allow(subject).to receive(:compute_percentage).and_return(usage_percentage)
    allow(pipelines_registry).to receive(:size).and_return(pipeline_count)
  end

  context "when memory usage goes above 10% heap" do
    let(:usage_percentage) { 45 }
    it "logs a warning message"  do
      expect(logger).to receive(:warn).with(/may reach up to #{usage_percentage}.*Consider.*pipeline.$/)
      subject.check(pipelines_registry)
    end
  end

  context "when memory usage is below 10% heap" do
    let(:usage_percentage) { 5 }
    it "logs a debug message" do
      expect(logger).to receive(:debug).with(/may reach up to #{usage_percentage}.*bigger\).$/)
      subject.check(pipelines_registry)
    end
  end

  context "when there are no pipelines" do
    let(:pipeline_count) { 0 }
    let(:usage_percentage) { 0 }
    it "should not log" do
      expect(logger).to_not receive(:warn)
      expect(logger).to_not receive(:debug)
      subject.check(pipelines_registry)
    end
  end
end
