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

require "paquet/shell_ui"

describe Paquet::ShellUi do
  let(:message) { "hello world" }

  subject { described_class.new }

  context "when debug is on" do
    before :all do
      @debug = ENV["debug"]
      ENV["DEBUG"] = "1"
    end

    after :all do
      ENV["DEBUG"] = @debug
    end

    it "show the debug statement" do
      expect(subject).to receive(:puts).with("[DEBUG]: #{message}")
      subject.debug(message)
    end
  end

  context "not in debug" do
    before :all do
      @debug = ENV["debug"]
      ENV["DEBUG"] = nil
    end

    after :all do
      ENV["DEBUG"] = @debug
    end

    it "doesnt show the debug statement" do
      expect(subject).not_to receive(:puts).with("[DEBUG]: #{message}")
      subject.debug(message)
    end
  end
end
