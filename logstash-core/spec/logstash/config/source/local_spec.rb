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

require "logstash/config/source/local"
require "rspec/expectations"
require "stud/temporary"
require "fileutils"
require "pathname"
require_relative "../../../support/helpers"
require_relative "../../../support/matchers"
require "spec_helper"
require "webmock/rspec"

describe LogStash::Config::Source::Local::ConfigStringLoader do
  subject { described_class }
  let(:config_string) { "input { generator {} } output { stdout {} }"}

  it "returns one config_parts" do
    expect(subject.read(config_string).size).to eq(1)
  end

  it "returns a valid config part" do
    config_part = subject.read(config_string).first
    expect(config_part).to be_a_source_with_metadata("string", "config_string", config_string)
  end
end

describe LogStash::Config::Source::Local::ConfigPathLoader do
  subject { described_class }

  context "no configs" do
    context "in the directory" do
      let(:directory) do
        p = Stud::Temporary.pathname
        FileUtils.mkdir_p(p)
        p
      end

      it "returns an empty array" do
        expect(subject.read(directory)).to be_empty
      end
    end

    context "target file doesn't exist" do
      let(:directory) do
        p = Stud::Temporary.pathname
        FileUtils.mkdir_p(p)
        ::File.join(p, "ls.conf")
      end

      it "returns an empty array" do
        expect(subject.read(directory)).to be_empty
      end
    end
  end

  context "when it exist" do
    shared_examples "read config from files" do
      let(:directory) { Stud::Temporary.pathname }

      before do
        files.each do |file, content|
          temporary_file(content, file, directory)
        end

        expect(files.size).to be >= 1
        expect(Dir.glob(::File.join(directory, "*")).size).to eq(files.size)
      end

      it "returns a `config_parts` per file" do
        expect(subject.read(reader_config).size).to eq(files.size)
      end

      it "returns alphabetically sorted parts" do
        parts = subject.read(reader_config)
        expect(parts.collect { |part| ::File.basename(part.id) }).to eq(files.keys.sort)
      end

      it "returns valid `config_parts`" do
        parts = subject.read(reader_config)

        parts.each do |part|
          basename = ::File.basename(part.id)
          file_path = ::File.expand_path(::File.join(directory, basename))
          content = files[basename]
          expect(part).to be_a_source_with_metadata("file", file_path, content)
        end
      end
    end

    context "when the files have invalid encoding" do
      let(:config_string) { "\x80" }
      let(:file_path) { Stud::Temporary.pathname }
      let(:file) { ::File.join(file_path, "wrong_encoding.conf") }

      before do
        FileUtils.mkdir_p(file_path)
        f = File.open(file, "wb") do |file|
          file.write(config_string)
        end
      end

      it "raises an exception" do
        # check against base name because on Windows long paths are shrinked in the exception message
        expect { subject.read(file_path) }.to raise_error LogStash::ConfigLoadingError, /.+#{::File.basename(file_path)}/
      end
    end

    context "when we target one file" do
      let(:reader_config) { ::File.join(directory, files.keys.first) }
      let(:files) {
        {
          "config1.conf" => "input1",
        }
      }

      include_examples "read config from files"
    end

    context "when we target a path with multiples files" do
      let(:reader_config) { directory }

      let(:files) {
        {
          "config1.conf" => "input1",
          "config2.conf" => "input2",
          "config3.conf" => "input3",
          "config4.conf" => "input4"
        }
      }

      include_examples "read config from files"
    end

    context "when there temporary files in the directory" do
      let(:reader_config) { ::File.join(directory, "conf*.conf") }

      let(:files) {
        {
          "config1.conf" => "input1",
          "config2.conf" => "input2",
          "config3.conf" => "input3",
          "config4.conf" => "input4"
        }
      }

      let(:other_files) do
        {
          "config1.conf~" => "input1",
          "config2.conf~" => "input2",
          "config3.conf~" => "input3",
          "config4.conf~" => "input4"
        }
      end

      include_examples "read config from files" do
        before do
          other_files.keys.shuffle.each do |file|
            content = files[file]
            temporary_file(content, file, directory)
          end

          # make sure we actually do some filtering
          expect(Dir.glob(::File.join(directory, "*")).size).to eq(other_files.size + files.size)
        end
      end
    end

    context "when the path is a wildcard" do
      let(:reader_config) { ::File.join(directory, "conf*.conf") }

      let(:files) {
        {
          "config1.conf" => "input1",
          "config2.conf" => "input2",
          "config3.conf" => "input3",
          "config4.conf" => "input4"
        }
      }

      let(:other_files) do
        {
          "bad1.conf" => "input1",
          "bad2.conf" => "input2",
          "bad3.conf" => "input3",
          "bad4.conf" => "input4"
        }
      end

      include_examples "read config from files" do
        before do
          other_files.keys.shuffle.each do |file|
            content = files[file]
            temporary_file(content, file, directory)
          end

          # make sure we actually do some filtering
          expect(Dir.glob(::File.join(directory, "*")).size).to eq(other_files.size + files.size)
        end
      end
    end

    context "URI defined path (file://..)" do
      let(:reader_config) { "file://#{::File.join(directory, files.keys.first)}" }
      let(:files) {
        {
          "config1.conf" => "input1",
        }
      }

      include_examples "read config from files"
    end

    context "relative path" do
      let(:reader_config) do
        FileUtils.mkdir_p(::File.join(directory, "inside"))
        ::File.join(directory, "inside", "../")
      end

      let(:files) {
        {
          "config2.conf" => "input1",
          "config1.conf" => "input2",
        }
      }

      include_examples "read config from files"
    end
  end
end

describe LogStash::Config::Source::Local::ConfigRemoteLoader do
  before :all do
    WebMock.disable_net_connect!
  end

  after :all do
    WebMock.allow_net_connect!
  end

  subject { described_class }

  let(:remote_url) { "http://test.dev/superconfig.conf" }

  context "when the remote configuration exist" do
    let(:config_string) { "input { generator {} } output { stdout {} }"}

    before do
      stub_request(:get, remote_url)
        .to_return({
        :body => config_string,
        :status => 200
      })
    end

    it "returns one config_parts" do
      expect(subject.read(remote_url).size).to eq(1)
    end

    it "returns a valid config part" do
      config_part = subject.read(remote_url).first
      expect(config_part).to be_a_source_with_metadata("http", remote_url, config_string)
    end
  end

  # I am aware that 656 http doesn't exist I am just testing the
  # catch all block
  [302, 404, 500, 403, 656].each do |code|
    context "when the remote return an error code: #{code}" do
      before do
        stub_request(:get, remote_url)
          .to_return({ :status => code })
      end

      it "raises the exception up" do
        expect { subject.read(remote_url) }.to raise_error LogStash::ConfigLoadingError
      end
    end
  end
end

describe LogStash::Config::Source::Local do
  let(:input_block) { "input { generator {} }" }
  let(:filter_block) { "filter { mutate {} } " }
  let(:output_block) { "output { elasticsearch {}}" }
  subject { described_class.new(settings) }

  context "when `config.string` and `config.path` are set`" do
    let(:config_file) { temporary_file(input_block) }

    let(:settings) do
      mock_settings(
        "config.string" => "#{filter_block} #{output_block}",
        "path.config" => config_file,
        "modules.cli" => [],
        "modules" => []
      )
    end

    # this should be impossible as the bootstrap checks should catch this
    it "raises an exception" do
      expect { subject.pipeline_configs }.to raise_error(LogStash::ConfigurationError)
    end
  end

  context "when only the `config.string` is set" do
    let(:settings) do
      mock_settings("config.string" => filter_block)
    end

    it "returns a config" do
      expect(subject.pipeline_configs.first.config_string).to include(filter_block)
    end
  end

  context "when only the `path.config` is set" do
    let(:config_file) { temporary_file(input_block) }
    let(:settings) do
      mock_settings("path.config" => config_file)
    end

    it "returns a config" do
      expect(subject.pipeline_configs.first.config_string).to include(input_block)
    end
  end

  context "when the `path.config` is an url" do
    let(:remote_url) { "http://test.dev/superconfig.conf" }

    before :all do
      WebMock.disable_net_connect!
    end

    after :all do
      WebMock.allow_net_connect!
    end

    before do
      stub_request(:get, remote_url)
        .to_return({
        :body => input_block,
        :status => 200
      })
    end

    let(:settings) do
      mock_settings("path.config" => remote_url)
    end

    it "returns a config" do
      expect(subject.pipeline_configs.first.config_string).to include(input_block)
    end

    context "when `config.string` is set" do
      let(:settings) do
        mock_settings(
          "path.config" => remote_url,
          "config.string" => filter_block
        )
      end

      it "raises an exception" do
        expect { subject.pipeline_configs }.to raise_error
      end
    end
  end

  context "incomplete configuration" do
    context "when using path.config" do
      let(:config_string) { filter_block }
      let(:config_path) do
        file = Stud::Temporary.file
        path = file.path
        file.write(config_string)
        file.close # we need to flush the write
        path
      end
      let(:settings) { mock_settings("path.config" => config_path) }

      it "doesn't add anything" do
        expect(subject.pipeline_configs.first.config_string).not_to include(LogStash::Config::Defaults.output, LogStash::Config::Defaults.input)
      end
    end

    context "when the input block is missing" do
      let(:settings) { mock_settings("config.string" => "#{filter_block} #{output_block}") }

      it "add stdin input" do
        expect(subject.pipeline_configs.first.config_string).to include(LogStash::Config::Defaults.input)
      end
    end

    context "when the output block is missing" do
      let(:settings) { mock_settings("config.string" => "#{input_block} #{filter_block}") }

      it "add stdout output" do
        expect(subject.pipeline_configs.first.config_string).to include(LogStash::Config::Defaults.output)
      end
    end

    context "when both the output block and input block are missing" do
      let(:settings) { mock_settings("config.string" => "#{filter_block}") }

      it "add stdin and output" do
        expect(subject.pipeline_configs.first.config_string).to include(LogStash::Config::Defaults.output, LogStash::Config::Defaults.input)
      end
    end

    context "when it has an input and an output" do
      let(:settings) { mock_settings("config.string" => "#{input_block} #{filter_block} #{output_block}") }

      it "doesn't add anything" do
        expect(subject.pipeline_configs.first.config_string).not_to include(LogStash::Config::Defaults.output, LogStash::Config::Defaults.input)
      end
    end
  end
end
