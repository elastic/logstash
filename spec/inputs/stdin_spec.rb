# encoding: utf-8
require "spec_helper"
require "socket"
require "logstash/inputs/stdin"

describe LogStash::Inputs::Stdin do
  context "codec (PR #1372)" do
    it "switches from plain to line" do
      require "logstash/codecs/plain"
      require "logstash/codecs/line"
      plugin = LogStash::Inputs::Stdin.new("codec" => LogStash::Codecs::Plain.new)
      plugin.register
      insist { plugin.codec }.is_a?(LogStash::Codecs::Line)
    end
    it "switches from json to json_lines" do
      require "logstash/codecs/json"
      require "logstash/codecs/json_lines"
      plugin = LogStash::Inputs::Stdin.new("codec" => LogStash::Codecs::JSON.new)
      plugin.register
      insist { plugin.codec }.is_a?(LogStash::Codecs::JSONLines)
    end
  end
end
