# encoding: utf-8
require "logstash/config/source/local"
require "rspec/expectations"
require "stud/temporary"
require "fileutils"
require "pathname"
require "spec_helper"
require "webmock/rspec"

RSpec::Matchers.define :be_a_config_part do |reader, source_id, config_string = nil|
  match do |actual|
   expect(actual.reader).to eq(reader)
   expect(actual.source_id).to eq(source_id)
   expect(actual.config_string).to match(config_string) unless config_string.nil?
  end
end

def temporary_file(content, file_name = Time.now.to_i.to_s, directory = Stud::Temporary.pathname)
  FileUtils.mkdir_p(directory)
  target = ::File.join(directory, file_name)

  File.open(target, "w+") do |f|
    f.write(content)
  end
  target
end

describe LogStash::Config::Source::Local::ConfigStringLoader do
  subject { described_class }
  let(:config_string) { "input { generator {} } output { stdout {} }"}

  it "returns one config_parts" do
    expect(subject.read(config_string).size).to eq(1)
  end

  it "returns a valid config part" do
    config_part = subject.read(config_string).first
    expect(config_part).to be_a_config_part(described_class.to_s, "config_string", config_string)
  end
end

describe LogStash::Config::Source::Local::ConfigPathLoader do
  subject { described_class }

  context "no configs" do
    context "in the directory" do
      let(:directory) do
        p =  Stud::Temporary.pathname
        FileUtils.mkdir_p(p)
        p
      end

      it "raises a config loading error" do
        expect { subject.read(directory) }.to raise_error LogStash::ConfigLoadingError, /Cannot load configuration for path/
      end
    end

    context "target file doesn't exist" do
      let(:directory) do
        p =  Stud::Temporary.pathname
        FileUtils.mkdir_p(p)
        ::File.join(p, "ls.conf")
      end

      it "raises a config loading error" do
        expect { subject.read(directory) }.to raise_error LogStash::ConfigLoadingError, /Cannot load configuration for path/
      end
    end
  end

  context "when it exist" do
    shared_examples "read config from files" do
      let(:directory) { Stud::Temporary.pathname }

      before do
        files.keys.shuffle.each do |file|
          content = files[file]
          temporary_file(content, file, directory)
        end
      end

      it "returns a `config_parts` per file" do
        expect(subject.read(reader_config).size).to eq(files.size)
      end

      it "returns alphabetically sorted parts" do
        parts = subject.read(reader_config)
        expect(parts.collect { |part| ::File.basename(part.source_id) }).to eq(files.keys.sort)
      end

      it "returns valid `config_parts`" do
        parts = subject.read(reader_config)

        parts.each do |part|
          basename = ::File.basename(part.source_id)
          file_path = ::File.join(directory, basename)
          content = files[basename]
          expect(part).to be_a_config_part(described_class.to_s, file_path, content)
        end
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
        current = Pathname.new(::File.dirname(__FILE__))
        target = Pathname.new(::File.join(directory, files.keys.first))
        target.relative_path_from(current).to_s
      end

      let(:files) {
        {
          "config1.conf" => "input1",
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
      expect(config_part).to be_a_config_part(described_class.to_s, remote_url, config_string)
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
end

