# encoding: utf-8
require "logstash/config/config_part"
require "logstash/config/source/local"

describe LogStash::Config::ConfigPart do
  let(:reader) { LogStash::Config::Source::Local::ConfigStringLoader.to_s }
  let(:source_id) { "config_string" }
  let(:config_string) { "input { generator {}}  output { stdout {} }"}

  subject { described_class.new(reader, source_id, config_string) }

  it "expose reader, source_id, source as instance methods" do
    expect(subject.reader).to eq(reader)
    expect(subject.source_id).to eq(source_id)
    expect(subject.config_string).to eq(config_string)
  end
end
