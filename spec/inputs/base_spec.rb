# encoding: utf-8
require "spec_helper"

describe "LogStash::Inputs::Base#fix_streaming_codecs" do
  it "should carry the charset setting along when switching" do
    require "logstash/inputs/tcp"
    require "logstash/codecs/plain"
    plain = LogStash::Codecs::Plain.new("charset" => "CP1252")
    tcp = LogStash::Inputs::Tcp.new("codec" => plain, "port" => 3333)
    tcp.instance_eval { fix_streaming_codecs }
    insist { tcp.codec.charset } == "CP1252"
  end
end
