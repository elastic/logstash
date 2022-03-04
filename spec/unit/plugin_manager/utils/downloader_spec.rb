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

require "pluginmanager/utils/downloader"
require "spec_helper"
require "webmock/rspec"

describe LogStash::PluginManager::Utils::Downloader::SilentFeedback do
  let(:max) { 500 }
  let(:status) { max * 0.5 }

  it "can create an instance" do
    expect { described_class.new(max) }.not_to raise_error
  end

  it "can receive `#update` calls" do
    expect { described_class.new(max).update(status) }.not_to raise_error
  end
end

describe LogStash::PluginManager::Utils::Downloader::ProgressbarFeedback do
  let(:max) { 500 }
  let(:status) { max * 0.5 }

  it "can create an instance" do
    expect(ProgressBar).to receive(:create).with(hash_including(:total => max))
    described_class.new(max)
  end

  it "can receive multiples `#update` calls" do
    feedback = described_class.new(max)
    expect(feedback.progress_bar).to receive(:progress=).with(status).twice
    feedback.update(status)
    feedback.update(status)
  end
end

describe LogStash::PluginManager::Utils::Downloader do
  subject { described_class }
  let(:port) { rand(2000..5000) }
  let(:url) { "https://localhost:#{port}/my-file.txt"}
  let(:content) { "its halloween, halloween!" }

  context "when the file exist" do
    before do
      stub_request(:get, url).to_return(
        { :status => 200,
          :body => content,
          :headers => {}}
      )
    end

    it "download the file to local temporary file" do
      expect(File.read(subject.fetch(url))).to match(content)
    end

    context "when an exception occur" do
      let(:temporary_path) { Stud::Temporary.pathname }

      before do
        expect(Net::HTTP::Get).to receive(:new).once.and_raise("Didn't work")
        expect(Stud::Temporary).to receive(:pathname).and_return(temporary_path)
      end

      it "deletes in progress file" do
        expect { subject.fetch(url) }.to raise_error(RuntimeError, /Didn't work/)
        expect(Dir.glob(::File.join(temporary_path, "**")).size).to eq(0)
      end
    end
  end

  context "when the file doesn't exist" do
    before do
      stub_request(:get, url).to_return(
        { :status => 404 }
      )
    end

    it "raises an exception" do
      expect { File.read(subject.fetch(url)) }.to raise_error(LogStash::PluginManager::FileNotFoundError)
    end
  end
end
