# encoding: utf-8
require "logstash/config/source/local"
require "rspec/expectations"
require "stud/temporary"
require "spec_helper"

RSpec::Matchers.define :be_a_config_part do |reader, source_id, config_string = nil|
  match do |actual|
   expect(actual.reader).to eq(reader)
   expect(actual.source_id).to eq(source_id)
   expect(actual.config_string).to match(config_string) unless config_string.nil?
  end
end

def temporary_file(content)
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

  let(:config_string) { "input { generator {} } output { stdout {} }"}

  context "when we target one file" do
    let(:config_file) do
      f = Stud::Temporary.file
      f.write(config_string)
      f.close
      f.path
    end

    it "returns one config_parts" do
      expect(subject.read(config_file).size).to eq(1)
    end

    it "returns a valid config part" do
      config_part = subject.read(config_file).first
      expect(config_part).to be_a_config_part(described_class.to_s, config_file, config_string)
    end
  end

  context "when we target a path with multiples files" do
  end
end

# describe LogStash::Config::Source::Local::ConfigRemoteLoader do
#   subject { described_class }

#   let(:remote_path) { "http://test.dev/superconfig.conf" }
#   let(:config_string) { "input { genrator {} } output { stdout {} }"}
# end
