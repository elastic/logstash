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

require "logstash/docgen/util"
require "spec_helper"

describe LogStash::Docgen::Util do
  subject { LogStash::Docgen::Util }

  context "time_execution" do
    it "prints the execution time to stdout" do
      output = capture do
        subject.time_execution do
          sleep(0.1)
        end
      end

      expect(output).to match(/Execution took: \d(\.\d+)?s/)
    end

    it "returns the value of the block" do
      value = subject.time_execution do
        1 + 2
      end

      expect(value).to eq(3)
    end
  end

  it "returns a red string" do
    expect(subject.red("Hello")).to eq("\e[31mHello\e[0m")
  end

  it "returns a green string" do
    expect(subject.green("Hello")).to eq("\e[32mHello\e[0m")
  end

  it "returns a yellow string" do
    expect(subject.yellow("Hello")).to eq("\e[33mHello\e[0m")
  end
end
