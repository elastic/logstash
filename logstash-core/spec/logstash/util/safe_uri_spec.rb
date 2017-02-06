# encoding: utf-8
require "logstash/util/safe_uri"
require "spec_helper"

module LogStash module Util
  describe SafeURI do
    describe "#clone" do
      subject { LogStash::Util::SafeURI.new("http://localhost:9200/uri?q=s") }
      it "allows modifying uri parameters" do
        cloned_safe_uri = subject.clone
        cloned_safe_uri.path = "/cloned"
        cloned_safe_uri.query = "a=b"
        expect(subject.path).to eq("/uri")
        expect(subject.query).to eq("q=s")
        expect(cloned_safe_uri.path).to eq("/cloned")
        expect(cloned_safe_uri.query).to eq("a=b")
      end
    end
  end
end end
