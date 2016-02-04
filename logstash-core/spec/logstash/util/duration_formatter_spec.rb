# encoding: utf-8
require "logstash/util/duration_formatter"
require "spec_helper"

describe LogStash::Util::DurationFormatter do
  let(:duration) { 3600 * 1000 } # in milliseconds

  it "returns a human format" do
    expect(subject.human_format(duration)).to eq("1h")
  end
end
