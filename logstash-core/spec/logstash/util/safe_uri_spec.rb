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

    describe "handling escapable fields" do
      let(:user) { "u%20" }
      let(:password) { "p%20ss" }
      let(:path) { "/a%20/path" }
      let(:query) { "a%20query&another=es%3dq" }
      let(:fragment) { "spacey%20fragment" }
      subject { LogStash::Util::SafeURI.new("http://#{user}:#{password}@example.net#{path}?#{query}\##{fragment}") }

      [:user, :password, :path, :query, :fragment].each do |field|
        it "should not escape the #{field} field" do
          expected = self.send(field)
          expect(subject.send(field)).to eq(expected)
        end
      end
    end
  end
end end
