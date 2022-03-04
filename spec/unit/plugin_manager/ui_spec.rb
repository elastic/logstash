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

require "pluginmanager/ui"
describe LogStash::PluginManager do
  it "set the a default ui" do
    expect(LogStash::PluginManager.ui).to be_kind_of(LogStash::PluginManager::Shell)
  end

  it "you can override the ui" do
    klass = Class.new
    LogStash::PluginManager.ui = klass
    expect(LogStash::PluginManager.ui).to be(klass)
    LogStash::PluginManager.ui = LogStash::PluginManager::Shell.new
  end
end

describe LogStash::PluginManager::Shell do
  let(:message) { "hello world" }

  [:info, :error, :warn].each do |level|
    context "Level: #{level}" do
      it "display the message to the user" do
        expect(subject).to receive(:puts).with(message)
        subject.send(level, message)
      end
    end
  end

  context "Debug" do
    context "when ENV['DEBUG'] is set" do
      before do
        @previous_value = ENV["DEBUG"]
        ENV["DEBUG"] = "1"
      end

      it "outputs the message" do
        expect(subject).to receive(:puts).with(message)
        subject.debug(message)
      end

      after do
        ENV["DEBUG"] = @previous_value
      end
    end

    context "when ENV['DEBUG'] is not set" do
      @previous_value = ENV["DEBUG"]
      ENV.delete("DEBUG")
    end

    it "doesn't outputs the message" do
      expect(subject).not_to receive(:puts).with(message)
      subject.debug(message)
    end

    after do
      ENV["DEBUG"] = @previous_value
    end
  end
end
