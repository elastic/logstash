# encoding: utf-8
require "spec_helper"
require "logstash/inputs/tcp"
require "logstash/codecs/plain"


describe "LogStash::Inputs::Base#fix_streaming_codecs" do

  let(:plain) { LogStash::Codecs::Plain.new("charset" => "CP1252") }
  let(:tcp)   { LogStash::Inputs::Tcp.new("codec" => plain, "port" => 3333) }

  it "carry the charset setting along when switching" do
    tcp.instance_eval { fix_streaming_codecs }
    expect(tcp.codec.charset).to eq("CP1252")
  end

end
